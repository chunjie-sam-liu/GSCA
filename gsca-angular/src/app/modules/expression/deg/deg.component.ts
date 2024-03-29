import { AfterViewInit, Component, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { ExpressionApiService } from '../expression-api.service';
import collectionList from 'src/app/shared/constants/collectionlist';
import { MatTableDataSource } from '@angular/material/table';
import { DegTableRecord } from 'src/app/shared/model/degtablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { animate, state, style, transition, trigger } from '@angular/animations';
import * as XLSX from 'xlsx';

@Component({
  selector: 'app-deg',
  templateUrl: './deg.component.html',
  styleUrls: ['./deg.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class DegComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // deg table data source
  dataSourceDegLoading = true;
  dataSourceDeg: MatTableDataSource<DegTableRecord>;
  showDEGTable = true;
  @ViewChild('paginatorDeg') paginatorDeg: MatPaginator;
  @ViewChild(MatSort) sortDeg: MatSort;
  displayedColumnsDeg = ['cancertype', 'symbol', 'tumor', 'normal', 'fc', 'pval', 'fdr', 'n_tumor'];
  displayedColumnsDegHeader = [
    'Cancer type',
    'Gene symbol',
    'Expr. tumor',
    'Expr. normal',
    'Fold change',
    'P value',
    'FDR',
    '# paired samples',
  ];
  expandedElement: DegTableRecord;
  expandedColumn: string;
  validCancertype: string;

  // degPlot
  degImage: any;
  degPdfURL: string;
  degImageLoading = true;
  showDEGImage = true;

  // single gene
  degSingleGeneImage: any;
  degSingleGenePdfURL: string;
  degSingleGeneImageLoading = false;
  showDEGSingleGeneImage = false;

  // single cancer type
  degSingleCancerTypeImage: any;
  degSingleCancerTypePdfURL: string;
  degSingleCancerTypeImageLoading = false;
  showdegSingleCancerTypeImage = false;

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    this.dataSourceDegLoading = true;
    this.degImageLoading = true;

    const postTerm = this._validCollection(this.searchTerm);
    this.validCancertype = this._validCancer(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceDegLoading = false;
      this.degImageLoading = false;
      this.showDEGTable = false;
      this.showDEGImage = false;
      window.alert(
        'The "GSEA score", "Differential expression", and "Differential GSVA" are based on cancer types with sufficient paired tumor-normal samples (>= 10), including THCA, KIRP, BLCA, LIHC, HNSC, BRCA, LUAD, PRAD, ESCA, KICH, LUSC, KIRC, STAD and COAD. \n\nPlease select at least one of these cancer types to access these analyses. \n\nOr you can explore "GSVA score" analysis or other gene expression analyses'
      );
    } else {
      //if (this.validCancertype.length < this.searchTerm.cancerTypeSelected.length) {
      //  window.alert(this.validCancertype);
      //}
      this.showDEGTable = true;
      this.expressionApiService.getDEGTable(postTerm).subscribe(
        (res) => {
          this.dataSourceDegLoading = false;
          this.dataSourceDeg = new MatTableDataSource(res);
          this.dataSourceDeg.paginator = this.paginatorDeg;
          this.dataSourceDeg.sort = this.sortDeg;
        },
        (err) => {
          this.showDEGTable = false;
        }
      );

      this.expressionApiService.getDEGPlot(postTerm).subscribe(
        (res) => {
          this.degPdfURL = this.expressionApiService.getResourcePlotURL(res.degplotuuid, 'pdf');
          this.expressionApiService.getResourcePlotBlob(res.degplotuuid, 'png').subscribe(
            (r) => {
              this.showDEGImage = true;
              this.degImageLoading = false;
              this._createImageFromBlob(r, 'degImage');
            },
            (e) => {
              this.showDEGImage = false;
            }
          );
        },
        (err) => {
          this.showDEGImage = false;
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
          case 'degImage':
            this.degImage = reader.result;
            break;
          case 'degSingleGeneImage':
            this.degSingleGeneImage = reader.result;
            break;
          case 'degSingleCancerTypeImage':
            this.degSingleCancerTypeImage = reader.result;
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
        return collectionList.deg.collnames[collectionList.deg.cancertypes.indexOf(val)];
      })
      .filter(Boolean);

    return st;
  }
  private _validCancer(st: ExprSearch): any {
    const validCancer = st.cancerTypeSelected
      .map((val) => {
        return collectionList.deg.cancertypes[collectionList.deg.cancertypes.indexOf(val)];
      })
      .filter(Boolean);

    return validCancer;
  }

  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceDeg.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceDeg.paginator) {
      this.dataSourceDeg.paginator.firstPage();
    }
  }

  public expandDetail(element: DegTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.degSingleGeneImageLoading = true;
      this.degSingleCancerTypeImageLoading = true;
      this.showDEGSingleGeneImage = false;
      this.showdegSingleCancerTypeImage = false;
      if (this.expandedColumn === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: collectionList.all_expr.cancertypes,
          validColl: collectionList.all_expr.collnames,
        };

        this.expressionApiService.getDEGSingleGenePlot(postTerm).subscribe(
          (res) => {
            this.degSingleGenePdfURL = this.expressionApiService.getResourcePlotURL(res.degplotsinglegeneuuid, 'pdf');
            this.expressionApiService.getResourcePlotBlob(res.degplotsinglegeneuuid, 'png').subscribe(
              (r) => {
                this._createImageFromBlob(r, 'degSingleGeneImage');
                this.degSingleGeneImageLoading = false;
                this.degSingleCancerTypeImageLoading = false;
                this.showDEGSingleGeneImage = true;
                this.showdegSingleCancerTypeImage = false;
              },
              (e) => {
                this.degSingleGeneImageLoading = false;
                this.degSingleCancerTypeImageLoading = false;
                this.showDEGSingleGeneImage = false;
                this.showdegSingleCancerTypeImage = false;
              }
            );
          },
          (err) => {
            this.degSingleGeneImageLoading = false;
            this.degSingleCancerTypeImageLoading = false;
            this.showDEGSingleGeneImage = false;
            this.showdegSingleCancerTypeImage = false;
          }
        );
      }
      if (this.expandedColumn === 'cancertype') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [collectionList.all_expr.collnames[collectionList.all_expr.cancertypes.indexOf(this.expandedElement.cancertype)]],
        };

        this.expressionApiService.getDEGSingleCancerTypePlot(postTerm).subscribe(
          (res) => {
            this.degSingleCancerTypePdfURL = this.expressionApiService.getResourcePlotURL(res.degplotsinglecancertypeuuid, 'pdf');
            this.expressionApiService.getResourcePlotBlob(res.degplotsinglecancertypeuuid, 'png').subscribe(
              (r) => {
                this._createImageFromBlob(r, 'degSingleCancerTypeImage');
                this.degSingleGeneImageLoading = false;
                this.degSingleCancerTypeImageLoading = false;
                this.showDEGSingleGeneImage = false;
                this.showdegSingleCancerTypeImage = true;
              },
              (e) => {
                this.degSingleGeneImageLoading = false;
                this.degSingleCancerTypeImageLoading = false;
                this.showDEGSingleGeneImage = false;
                this.showdegSingleCancerTypeImage = false;
              }
            );
          },
          (err) => {
            this.degSingleGeneImageLoading = false;
            this.degSingleCancerTypeImageLoading = false;
            this.showDEGSingleGeneImage = false;
            this.showdegSingleCancerTypeImage = false;
          }
        );
      }
    } else {
      this.degSingleGeneImageLoading = false;
      this.degSingleCancerTypeImageLoading = false;
      this.showDEGSingleGeneImage = false;
      this.showdegSingleCancerTypeImage = false;
    }
  }

  public triggerDetail(element: DegTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }

  public exportExcel() {
    const workSheet = XLSX.utils.json_to_sheet(this.dataSourceDeg.data, { header: this.displayedColumnsDeg });
    const workBook: XLSX.WorkBook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workBook, workSheet, 'SheetName');
    XLSX.writeFile(workBook, 'DifferentialExpressionTable.xlsx');
  }
}
