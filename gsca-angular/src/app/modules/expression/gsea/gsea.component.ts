import { AfterViewInit, Component, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { ExpressionApiService } from '../expression-api.service';
import collectionList from 'src/app/shared/constants/collectionlist';
import { MatTableDataSource } from '@angular/material/table';
import { GSEATableRecord } from 'src/app/shared/model/gseatablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { animate, state, style, transition, trigger } from '@angular/animations';
import * as XLSX from 'xlsx';
@Component({
  selector: 'app-gsea',
  templateUrl: './gsea.component.html',
  styleUrls: ['./gsea.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class GseaComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  dataSourceGSEALoading = true;
  dataSourceGSEA: MatTableDataSource<GSEATableRecord>;
  showGSEATable = true;
  @ViewChild('paginatorGSEA') paginatorGSEA: MatPaginator;
  @ViewChild(MatSort) sortGSEA: MatSort;
  displayedColumnsGSEA = ['cancertype', 'ES', 'NES', 'pval', 'padj'];
  displayedColumnsGSEAHeader = ['Cancer type', 'ES', 'NES', 'P value', 'P adj.'];
  expandedElement: GSEATableRecord;
  expandedColumn: string;

  GSEAImage: any;
  GSEAPdfURL: string;
  GSEAImageLoading = true;
  showGSEAImage = true;

  // single gene
  gseaResourceUUID: string;
  gseaSingleCancerTypeImage: any;
  gseaSingleCancerTypePdfURL: string;
  gseaSingleCancerTypeImageLoading = true;
  showgseaSingleCancerTypeImage = false;

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    this.dataSourceGSEALoading = true;
    this.GSEAImageLoading = true;
    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceGSEALoading = false;
      this.GSEAImageLoading = false;
      this.showGSEATable = false;
      this.showGSEAImage = false;
      window.alert(
        'The GSEA enrichment analysis is based on differential analysis, please select at least one cancer type which has at least ten tumor-normal paired samples. These cancer types including THCA, KIRP, BLCA, LIHC, HNSC, BRCA, LUAD, PRAD, ESCA, KICH, LUSC, KIRC, STAD and COAD.'
      );
    } else {
      this.expressionApiService.getGSEAAnalysis(postTerm).subscribe(
        (res) => {
          this.gseaResourceUUID = res.uuidname;
          this.expressionApiService.getExprGSEAPlot(res.uuidname).subscribe(
            (exprgseauuids) => {
              this.showGSEATable = true;
              this.expressionApiService.getResourceTable('preanalysised_gsea_expr', exprgseauuids.exprgseatableuuid).subscribe(
                (r) => {
                  this.dataSourceGSEALoading = false;
                  this.dataSourceGSEA = new MatTableDataSource(r);
                  this.dataSourceGSEA.paginator = this.paginatorGSEA;
                  this.dataSourceGSEA.sort = this.sortGSEA;
                },
                (e) => {
                  this.showGSEATable = false;
                }
              );
              this.GSEAPdfURL = this.expressionApiService.getResourcePlotURL(exprgseauuids.exprgseaplotuuid, 'pdf');
              this.expressionApiService.getResourcePlotBlob(exprgseauuids.exprgseaplotuuid, 'png').subscribe(
                (r) => {
                  this.showGSEAImage = true;
                  this.GSEAImageLoading = false;
                  this._createImageFromBlob(r, 'GSEAImage');
                },
                (e) => {
                  this.showGSEAImage = false;
                }
              );
            },
            (e) => {
              this.dataSourceGSEALoading = false;
              this.GSEAImageLoading = false;
              this.showGSEATable = false;
              this.showGSEAImage = false;
            }
          );
        },
        (err) => {
          this.showGSEATable = false;
          this.showGSEAImage = false;
        }
      );
    }
  }

  ngAfterViewInit(): void {}

  private _validCollection(st: ExprSearch): any {
    st.validColl = st.cancerTypeSelected
      .map((val) => {
        return collectionList.deg.collnames[collectionList.deg.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }

  private _createImageFromBlob(res: Blob, present: string) {
    const reader = new FileReader();
    reader.addEventListener(
      'load',
      () => {
        switch (present) {
          case 'GSEAImage':
            this.GSEAImage = reader.result;
            break;
          case 'gseaSingleCancerTypeImage':
            this.gseaSingleCancerTypeImage = reader.result;
            break;
        }
      },
      false
    );
    if (res) {
      reader.readAsDataURL(res);
    }
  }

  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceGSEA.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceGSEA.paginator) {
      this.dataSourceGSEA.paginator.firstPage();
    }
  }
  public expandDetail(element: GSEATableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.gseaSingleCancerTypeImageLoading = true;
      this.showgseaSingleCancerTypeImage = false;
      if (this.expandedColumn === 'cancertype') {
        const postTerm = {
          uuidname: this.gseaResourceUUID,
          cancerTypeSelected: this.expandedElement.cancertype,
        };
        this.expressionApiService.getGSEASingleCancerTypePlot(postTerm.uuidname, postTerm.cancerTypeSelected).subscribe(
          (res) => {
            this.gseaSingleCancerTypePdfURL = this.expressionApiService.getResourcePlotURL(res.gseaplotsinglecancertypeuuid, 'pdf');
            this.expressionApiService.getResourcePlotBlob(res.gseaplotsinglecancertypeuuid, 'png').subscribe(
              (r) => {
                this._createImageFromBlob(r, 'gseaSingleCancerTypeImage');
                this.gseaSingleCancerTypeImageLoading = false;
                this.showgseaSingleCancerTypeImage = true;
              },
              (e) => {
                this.gseaSingleCancerTypeImageLoading = false;
                this.showgseaSingleCancerTypeImage = false;
              }
            );
          },
          (err) => {
            this.gseaSingleCancerTypeImageLoading = false;
            this.showgseaSingleCancerTypeImage = false;
          }
        );
      }
    } else {
      this.gseaSingleCancerTypeImageLoading = false;
      this.showgseaSingleCancerTypeImage = false;
    }
  }
  public triggerDetail(element: GSEATableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
  public exportExcel() {
    const workSheet = XLSX.utils.json_to_sheet(this.dataSourceGSEA.data, { header: this.displayedColumnsGSEA });
    const workBook: XLSX.WorkBook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workBook, workSheet, 'SheetName');
    XLSX.writeFile(workBook, 'GseaTable.xlsx');
  }
}
