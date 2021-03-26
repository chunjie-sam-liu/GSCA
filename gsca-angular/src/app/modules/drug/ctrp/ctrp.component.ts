import { AfterViewInit, Component, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { DrugApiService } from '../drug-api.service';
import collectionList from 'src/app/shared/constants/collectionlist';
import { MatTableDataSource } from '@angular/material/table';
import { DrugTableRecord } from 'src/app/shared/model/gdsctablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { animate, state, style, transition, trigger } from '@angular/animations';
import * as XLSX from 'xlsx';
@Component({
  selector: 'app-ctrp',
  templateUrl: './ctrp.component.html',
  styleUrls: ['./ctrp.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class CtrpComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // ctrp table data source
  dataSourceCtrpLoading = true;
  dataSourceCtrp: MatTableDataSource<DrugTableRecord>;
  showCTRPTable = true;
  @ViewChild('paginatorCtrp') paginatorCtrp: MatPaginator;
  @ViewChild(MatSort) sortCtrp: MatSort;
  displayedColumnsCtrp = ['symbol', 'drug', 'cor', 'fdr'];
  displayedColumnsCtrpHeader = ['Gene symbol', 'Drug name', 'Correlation', 'FDR'];
  expandedElement: DrugTableRecord;
  expandedColumn: string;

  // ctrpPlot
  ctrpImage: any;
  ctrpPdfURL: string;
  ctrpImageLoading = true;
  showCTRPImage = false;

  // single gene
  ctrpSingleGeneImage: any;
  ctrpSingleGenePdfURL: string;
  ctrpSingleGeneImageLoading = true;
  showCTRPSingleGeneImage = false;

  constructor(private drugApiService: DrugApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    this.dataSourceCtrpLoading = true;
    this.ctrpImageLoading = true;

    // const postTerm = this._validCollection(this.searchTerm);
    const postTerm = {
      validSymbol: this.searchTerm.validSymbol,
      validColl: collectionList.ctrp_cor_expr.collnames,
    };

    if (!postTerm.validColl) {
      this.dataSourceCtrpLoading = false;
      this.ctrpImageLoading = false;
      this.showCTRPTable = false;
      this.showCTRPImage = false;
    } else {
      this.showCTRPTable = true;
      this.drugApiService.getCTRPTable(postTerm).subscribe(
        (res) => {
          this.dataSourceCtrpLoading = false;
          this.dataSourceCtrp = new MatTableDataSource(res);
          this.dataSourceCtrp.paginator = this.paginatorCtrp;
          this.dataSourceCtrp.sort = this.sortCtrp;
        },
        (err) => {
          this.showCTRPTable = false;
        }
      );

      this.drugApiService.getCTRPPlot(postTerm).subscribe(
        (res) => {
          this.ctrpPdfURL = this.drugApiService.getResourcePlotURL(res.ctrpplotuuid, 'pdf');
          this.drugApiService.getResourcePlotBlob(res.ctrpplotuuid, 'png').subscribe(
            (r) => {
              this.showCTRPImage = true;
              this.ctrpImageLoading = false;
              this._createImageFromBlob(r, 'ctrpImage');
            },
            (e) => {
              this.showCTRPImage = false;
            }
          );
        },
        (err) => {
          this.showCTRPImage = false;
        }
      );
    }
  }

  ngAfterViewInit(): void {}

  private _createImageFromBlob(res: Blob, present: string) {
    const reader = new FileReader();
    reader.addEventListener(
      'load',
      () => {
        switch (present) {
          case 'ctrpImage':
            this.ctrpImage = reader.result;
            break;
          case 'ctrpSingleGeneImage':
            this.ctrpSingleGeneImage = reader.result;
            break;
          /* case 'ctrpSingleCancerTypeImage':
            this.ctrpSingleCancerTypeImage = reader.result;
            break; */
        }
      },
      false
    );
    if (res) {
      reader.readAsDataURL(res);
    }
  }

  /* private _validCollection(st: ExprSearch): any {
    st.validColl = st.cancerTypeSelected
      .map((val) => {
        return collectionList.ctrp_cor_expr.collnames[collectionList.ctrp_cor_expr.cancertypes.indexOf(val)];
      })
      .filter(Boolean);

    return st;
  } */

  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceCtrp.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceCtrp.paginator) {
      this.dataSourceCtrp.paginator.firstPage();
    }
  }

  public expandDetail(element: DrugTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.ctrpSingleGeneImageLoading = true;
      this.showCTRPSingleGeneImage = false;
      if (this.expandedColumn === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: collectionList.ctrp_cor_expr.cancertypes,
          validColl: collectionList.ctrp_cor_expr.collnames,
          surType: [this.expandedElement.drug],
        };

        this.drugApiService.getCTRPSingleGenePlot(postTerm).subscribe(
          (res) => {
            this.ctrpSingleGenePdfURL = this.drugApiService.getResourcePlotURL(res.ctrpsinglegeneuuid, 'pdf');
            this.drugApiService.getResourcePlotBlob(res.ctrpsinglegeneuuid, 'png').subscribe(
              (r) => {
                this._createImageFromBlob(r, 'ctrpSingleGeneImage');
                this.ctrpSingleGeneImageLoading = false;
                this.showCTRPSingleGeneImage = true;
              },
              (e) => {
                this.ctrpSingleGeneImageLoading = false;
                this.showCTRPSingleGeneImage = false;
              }
            );
          },
          (err) => {
            this.ctrpSingleGeneImageLoading = false;
            this.showCTRPSingleGeneImage = false;
          }
        );
      }
      /* if (this.expandedColumn === 'cancertype') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [collectionList.all_expr.collnames[collectionList.all_expr.cancertypes.indexOf(this.expandedElement.cancertype)]],
        };

        this.drugApiService.getCTRPSingleCancerTypePlot(postTerm).subscribe(
          (res) => {
            this.ctrpSingleCancerTypePdfURL = this.drugApiService.getResourcePlotURL(res.ctrpplotsinglecancertypeuuid, 'pdf');
            this.drugApiService.getResourcePlotBlob(res.ctrpplotsinglecancertypeuuid, 'png').subscribe(
              (r) => {
                this._createImageFromBlob(r, 'ctrpSingleCancerTypeImage');
                this.ctrpSingleGeneImageLoading = false;
                this.ctrpSingleCancerTypeImageLoading = false;
                this.showCTRPSingleGeneImage = false;
                this.showctrpSingleCancerTypeImage = true;
              },
              (e) => {
                this.ctrpSingleGeneImageLoading = false;
                this.ctrpSingleCancerTypeImageLoading = false;
                this.showCTRPSingleGeneImage = false;
                this.showctrpSingleCancerTypeImage = false;
              }
            );
          },
          (err) => {
            this.ctrpSingleGeneImageLoading = false;
            this.ctrpSingleCancerTypeImageLoading = false;
            this.showCTRPSingleGeneImage = false;
            this.showctrpSingleCancerTypeImage = false;
          }
        );
      } */
    } else {
      this.ctrpSingleGeneImageLoading = false;
      this.showCTRPSingleGeneImage = false;
    }
  }

  public triggerDetail(element: DrugTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
  public exportExcel() {
    const workSheet = XLSX.utils.json_to_sheet(this.dataSourceCtrp.data, { header: this.displayedColumnsCtrp });
    const workBook: XLSX.WorkBook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workBook, workSheet, 'SheetName');
    XLSX.writeFile(workBook, 'CtrpDrugIC50AndExpTable.xlsx');
  }
}
