import { Component, Input, OnInit, ViewChild, OnChanges, SimpleChanges, AfterViewChecked } from '@angular/core';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { RPPATableRecord } from 'src/app/shared/model/rppatablerecord';
import { ExpressionApiService } from '../expression-api.service';
import { animate, state, style, transition, trigger } from '@angular/animations';
import * as XLSX from 'xlsx';

@Component({
  selector: 'app-ppar',
  templateUrl: './ppar.component.html',
  styleUrls: ['./ppar.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class PparComponent implements OnInit, OnChanges, AfterViewChecked {
  @Input() searchTerm: ExprSearch;

  // rppa table
  RPPATableLoading = true;
  RPPATable: MatTableDataSource<RPPATableRecord>;
  showRPPATable = true;
  @ViewChild('paginatorRPPA') paginatorRPPA: MatPaginator;
  @ViewChild(MatSort) sortRPPA: MatSort;
  displayedColumnsRPPA = ['cancertype', 'symbol', 'pathway', 'fdr', 'class'];
  displayedColumnsRPPAHeader = ['Cancer type', 'Gene symbol', 'Pathway', 'FDR', 'Potential effects of gene mRNA on pathway activity'];
  expandedElement: RPPATableRecord;
  expandedColumn: string;

  // RPPA image
  RPPAImageLoading = true;
  RPPAImage: any;
  showRPPAImage = true;
  RPPAImagePdfURL: string;

  // single gene
  RPPASingleGeneImage: any;
  RPPASingleGeneImageLoading = true;
  showRPPASingleGeneImage = false;
  RPPASingleGenePdfURL: string;

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.RPPAImageLoading = true;
    this.RPPATableLoading = true;
    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.RPPAImageLoading = false;
      this.RPPATableLoading = false;
      this.showRPPAImage = false;
      this.showRPPATable = false;
    } else {
      this.showRPPATable = true;
      this.expressionApiService.getRPPATable(postTerm).subscribe(
        (res) => {
          this.RPPATableLoading = false;
          this.RPPATable = new MatTableDataSource(res);
          this.RPPATable.paginator = this.paginatorRPPA;
          this.RPPATable.sort = this.sortRPPA;
        },
        (err) => {
          this.showRPPATable = false;
          this.RPPATableLoading = false;
        }
      );
      this.expressionApiService.getRPPAPlot(postTerm).subscribe(
        (res) => {
          // RPPA point
          this.RPPAImagePdfURL = this.expressionApiService.getResourcePlotURL(res.rppaPointuuid, 'pdf');
          this.expressionApiService.getResourcePlotBlob(res.rppaPointuuid, 'png').subscribe(
            (r) => {
              this.showRPPAImage = true;
              this.RPPAImageLoading = false;
              this._createImageFromBlob(r, 'RPPAImage');
            },
            (e) => {
              this.showRPPAImage = false;
            }
          );
        },
        (err) => {
          this.showRPPAImage = false;
        }
      );
    }
  }

  ngAfterViewChecked(): void {
    // Called after every check of the component's view. Applies to components only.
    // Add 'implements AfterViewChecked' to the class.
  }

  private _createImageFromBlob(res: Blob, present: string) {
    const reader = new FileReader();
    reader.addEventListener(
      'load',
      () => {
        switch (present) {
          case 'RPPAImage':
            this.RPPAImage = reader.result;
            break;
          case 'RPPASingleGeneImage':
            this.RPPASingleGeneImage = reader.result;
            break;
        }
      },
      false
    );
    if (res) {
      reader.readAsDataURL(res);
    }
  }

  private _validCollection(st: ExprSearch): any {
    st.validColl = st.cancerTypeSelected
      .map((val) => {
        return collectionlist.rppa_diff.collnames[collectionlist.rppa_diff.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }

  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.RPPATable.filter = filterValue.trim().toLowerCase();

    if (this.RPPATable.paginator) {
      this.RPPATable.paginator.firstPage();
    }
  }

  public expandDetail(element: RPPATableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.RPPASingleGeneImageLoading = true;
      this.showRPPASingleGeneImage = false;
      if (this.expandedColumn === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [collectionlist.rppa_diff.collnames[collectionlist.rppa_diff.cancertypes.indexOf(this.expandedElement.cancertype)]],
          surType: [this.expandedElement.pathway],
        };

        this.expressionApiService.getRPPASingleGenePlot(postTerm).subscribe(
          (res) => {
            this.RPPASingleGenePdfURL = this.expressionApiService.getResourcePlotURL(res.rppasinglegeneuuid, 'pdf');
            this.expressionApiService.getResourcePlotBlob(res.rppasinglegeneuuid, 'png').subscribe(
              (r) => {
                this._createImageFromBlob(r, 'RPPASingleGeneImage');
                this.RPPASingleGeneImageLoading = false;
                this.showRPPASingleGeneImage = true;
              },
              (e) => {
                this.RPPASingleGeneImageLoading = false;
                this.showRPPASingleGeneImage = false;
              }
            );
          },
          (err) => {
            this.RPPASingleGeneImageLoading = false;
            this.showRPPASingleGeneImage = false;
          }
        );
      }
    } else {
      this.RPPASingleGeneImageLoading = false;
      this.showRPPASingleGeneImage = false;
    }
  }

  public triggerDetail(element: RPPATableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
  public exportExcel() {
    const workSheet = XLSX.utils.json_to_sheet(this.RPPATable.data, { header: this.displayedColumnsRPPA });
    const workBook: XLSX.WorkBook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workBook, workSheet, 'SheetName');
    XLSX.writeFile(workBook, 'ExpressionAndRPPATable.xlsx');
  }
}
