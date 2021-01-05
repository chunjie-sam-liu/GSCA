import { AfterViewInit, Component, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { DrugApiService } from '../drug-api.service';
import collectionList from 'src/app/shared/constants/collectionlist';
import { MatTableDataSource } from '@angular/material/table';
import { DrugTableRecord } from 'src/app/shared/model/gdsctablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { animate, state, style, transition, trigger } from '@angular/animations';

@Component({
  selector: 'app-gdsc',
  templateUrl: './gdsc.component.html',
  styleUrls: ['./gdsc.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class GdscComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // gdsc table data source
  dataSourceGdscLoading = true;
  dataSourceGdsc: MatTableDataSource<DrugTableRecord>;
  showGDSCTable = true;
  @ViewChild('paginatorGdsc') paginatorGdsc: MatPaginator;
  @ViewChild(MatSort) sortGdsc: MatSort;
  displayedColumnsGdsc = ['symbol', 'drug', 'cor', 'fdr'];
  displayedColumnsGdscHeader = ['Gene symbol', 'Drug name', 'Correlation', 'FDR'];
  expandedElement: DrugTableRecord;
  expandedColumn: string;

  // gdscPlot
  gdscImage: any;
  gdscPdfURL: string;
  gdscImageLoading = true;
  showGDSCImage = false;

  // single gene
  gdscSingleGeneImage: any;
  gdscSingleGenePdfURL: string;
  gdscSingleGeneImageLoading = true;
  showGDSCSingleGeneImage = false;

  constructor(private drugApiService: DrugApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    this.dataSourceGdscLoading = true;
    this.gdscImageLoading = true;

    // const postTerm = this._validCollection(this.searchTerm);
    // const postTerm = this.searchTerm;
    const postTerm = {
      validSymbol: this.searchTerm.validSymbol,
      validColl: collectionList.gdsc_cor_expr.collnames,
    };

    if (!postTerm.validColl) {
      this.dataSourceGdscLoading = false;
      this.gdscImageLoading = false;
      this.showGDSCTable = false;
      this.showGDSCImage = false;
    } else {
      this.showGDSCTable = true;
      this.drugApiService.getGDSCTable(postTerm).subscribe(
        (res) => {
          this.dataSourceGdscLoading = false;
          this.dataSourceGdsc = new MatTableDataSource(res);
          this.dataSourceGdsc.paginator = this.paginatorGdsc;
          this.dataSourceGdsc.sort = this.sortGdsc;
        },
        (err) => {
          this.showGDSCTable = false;
        }
      );

      this.drugApiService.getGDSCPlot(postTerm).subscribe(
        (res) => {
          this.gdscPdfURL = this.drugApiService.getResourcePlotURL(res.gdscplotuuid, 'pdf');
          this.drugApiService.getResourcePlotBlob(res.gdscplotuuid, 'png').subscribe(
            (r) => {
              this.showGDSCImage = true;
              this.gdscImageLoading = false;
              this._createImageFromBlob(r, 'gdscImage');
            },
            (e) => {
              this.showGDSCImage = false;
            }
          );
        },
        (err) => {
          this.showGDSCImage = false;
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
          case 'gdscImage':
            this.gdscImage = reader.result;
            break;
          case 'gdscSingleGeneImage':
            this.gdscSingleGeneImage = reader.result;
            break;
          /* case 'gdscSingleCancerTypeImage':
            this.gdscSingleCancerTypeImage = reader.result;
            break; */
        }
      },
      false
    );
    if (res) {
      reader.readAsDataURL(res);
    }
  }

  /*   private _validCollection(st: ExprSearch): any {
    st.validColl = st.cancerTypeSelected
      .map((val) => {
        return collectionList.gdsc_cor_expr.collnames[collectionList.gdsc_cor_expr.cancertypes.indexOf(val)];
      })
      .filter(Boolean);

    return st;
  } */

  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceGdsc.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceGdsc.paginator) {
      this.dataSourceGdsc.paginator.firstPage();
    }
  }

  public expandDetail(element: DrugTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.gdscSingleGeneImageLoading = true;
      this.showGDSCSingleGeneImage = false;
      if (this.expandedColumn === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: collectionList.gdsc_cor_expr.cancertypes,
          validColl: collectionList.gdsc_cor_expr.collnames,
          surType: [this.expandedElement.drug],
        };

        this.drugApiService.getGDSCSingleGenePlot(postTerm).subscribe(
          (res) => {
            this.gdscSingleGenePdfURL = this.drugApiService.getResourcePlotURL(res.gdscsinglegeneuuid, 'pdf');
            this.drugApiService.getResourcePlotBlob(res.gdscsinglegeneuuid, 'png').subscribe(
              (r) => {
                this._createImageFromBlob(r, 'gdscSingleGeneImage');
                this.gdscSingleGeneImageLoading = false;
                this.showGDSCSingleGeneImage = true;
              },
              (e) => {
                this.gdscSingleGeneImageLoading = false;
                this.showGDSCSingleGeneImage = false;
              }
            );
          },
          (err) => {
            this.gdscSingleGeneImageLoading = false;
            this.showGDSCSingleGeneImage = false;
          }
        );
      }
      /* if (this.expandedColumn === 'cancertype') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [collectionList.all_expr.collnames[collectionList.all_expr.cancertypes.indexOf(this.expandedElement.cancertype)]],
        };

        this.drugApiService.getGDSCSingleCancerTypePlot(postTerm).subscribe(
          (res) => {
            this.gdscSingleCancerTypePdfURL = this.drugApiService.getResourcePlotURL(res.gdscplotsinglecancertypeuuid, 'pdf');
            this.drugApiService.getResourcePlotBlob(res.gdscplotsinglecancertypeuuid, 'png').subscribe(
              (r) => {
                this._createImageFromBlob(r, 'gdscSingleCancerTypeImage');
                this.gdscSingleGeneImageLoading = false;
                this.gdscSingleCancerTypeImageLoading = false;
                this.showGDSCSingleGeneImage = false;
                this.showgdscSingleCancerTypeImage = true;
              },
              (e) => {
                this.gdscSingleGeneImageLoading = false;
                this.gdscSingleCancerTypeImageLoading = false;
                this.showGDSCSingleGeneImage = false;
                this.showgdscSingleCancerTypeImage = false;
              }
            );
          },
          (err) => {
            this.gdscSingleGeneImageLoading = false;
            this.gdscSingleCancerTypeImageLoading = false;
            this.showGDSCSingleGeneImage = false;
            this.showgdscSingleCancerTypeImage = false;
          }
        );
      } */
    } else {
      this.gdscSingleGeneImageLoading = false;
      this.showGDSCSingleGeneImage = false;
    }
  }

  public triggerDetail(element: DrugTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
}
