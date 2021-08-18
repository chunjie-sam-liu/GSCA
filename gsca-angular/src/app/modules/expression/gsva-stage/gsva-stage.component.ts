import { Component, OnInit, OnChanges, AfterViewInit, SimpleChanges, Input, ViewChild } from '@angular/core';
import { ExpressionApiService } from './../expression-api.service';
import { ExprSearch } from './../../../shared/model/exprsearch';
import collectionList from 'src/app/shared/constants/collectionlist';
import { MatTableDataSource } from '@angular/material/table';
import { GSVAStageTableRecord } from 'src/app/shared/model/gsvastagetablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import * as XLSX from 'xlsx';
// import { animate, state, style, transition, trigger } from '@angular/animations';

@Component({
  selector: 'app-gsva-stage',
  templateUrl: './gsva-stage.component.html',
  styleUrls: ['./gsva-stage.component.css'],
  /* animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ], */
})
export class GsvaStageComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // GSVA stage table
  dataSourceGSVAStageLoading = true;
  dataSourceGSVAStage: MatTableDataSource<GSVAStageTableRecord>;
  showGSVAStageTable = true;
  @ViewChild('paginatorGSVAStage') paginatorGSVAStage: MatPaginator;
  @ViewChild(MatSort) sortGSVAStage: MatSort;
  displayedColumnsGSVAStage = ['cancertype', 'stage_type', 'diff_p', 'trend_p', 'trend_score', 'StageI', 'StageII', 'StageIII', 'StageIV'];
  displayedColumnsGSVAStageHeader = [
    'Cancer type',
    'Stage type',
    'P value of difference test',
    'P value of trend test',
    'Score of trend test',
    'Stage I (mean/n)',
    'Stage II (mean/n)',
    'Stage III (mean/n)',
    'Stage IV (mean/n)',
  ];
  expandedElement: GSVAStageTableRecord;
  expandedColumn: string;

  // GSVA stage image
  GSVAStageImage: any;
  GSVAStagePdfURL: string;
  GSVAStageImageLoading = true;
  showGSVAStageImage = true;

  // GSVA stage image
  GSVAStageTrendImage: any;
  GSVAStageTrendPdfURL: string;
  GSVAStageTrendImageLoading = true;
  showGSVAStageTrendImage = true;

  // GSVA stage single cancer image
  /* gsvaStageResourceUUID: string;
  GSVAStageSingleCancerImage: any;
  GSVAStageSingleCancerPdfURL: string;
  GSVAStageSingleCancerImageLoading = true;
  showGSVAStageSingleCancerImage = true; */

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    this.dataSourceGSVAStageLoading = true;
    this.GSVAStageImageLoading = true;
    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceGSVAStageLoading = false;
      this.GSVAStageImageLoading = false;
      this.showGSVAStageTable = false;
      this.showGSVAStageImage = false;
    } else {
      this.expressionApiService.getGSVAAnalysis(postTerm).subscribe(
        (res) => {
          // this.gsvaStageResourceUUID = res.uuidname;
          this.expressionApiService.getExprStageGSVAPlot(res.uuidname).subscribe(
            (exprgsvauuids) => {
              this.showGSVAStageTable = true;
              this.expressionApiService.getResourceTable('preanalysised_gsva_stage', exprgsvauuids.exprstagegsvatableuuid).subscribe(
                (r) => {
                  this.dataSourceGSVAStageLoading = false;
                  this.dataSourceGSVAStage = new MatTableDataSource(r);
                  this.dataSourceGSVAStage.paginator = this.paginatorGSVAStage;
                  this.dataSourceGSVAStage.sort = this.sortGSVAStage;
                },
                (e) => {
                  this.showGSVAStageTable = false;
                }
              );
              this.GSVAStagePdfURL = this.expressionApiService.getResourcePlotURL(exprgsvauuids.exprstagegsvaboxplotuuid, 'pdf');
              this.expressionApiService.getResourcePlotBlob(exprgsvauuids.exprstagegsvaboxplotuuid, 'png').subscribe(
                (r) => {
                  this.showGSVAStageImage = true;
                  this.GSVAStageImageLoading = false;
                  this._createImageFromBlob(r, 'GSVAStageImage');
                },
                (e) => {
                  this.showGSVAStageImage = false;
                }
              );
              this.GSVAStageTrendPdfURL = this.expressionApiService.getResourcePlotURL(exprgsvauuids.exprstagegsvatrendplotuuid, 'pdf');
              this.expressionApiService.getResourcePlotBlob(exprgsvauuids.exprstagegsvatrendplotuuid, 'png').subscribe(
                (r) => {
                  this.showGSVAStageTrendImage = true;
                  this.GSVAStageTrendImageLoading = false;
                  this._createImageFromBlob(r, 'GSVAStageTrendImage');
                },
                (e) => {
                  this.showGSVAStageTrendImage = false;
                }
              );
            },
            (e) => {
              this.dataSourceGSVAStageLoading = false;
              this.GSVAStageImageLoading = false;
              this.GSVAStageTrendImageLoading = false;
              this.showGSVAStageTable = false;
              this.showGSVAStageImage = false;
              this.showGSVAStageTrendImage = false;
            }
          );
        },
        (err) => {
          this.showGSVAStageTable = false;
          this.showGSVAStageImage = false;
          this.showGSVAStageTrendImage = false;
        }
      );
    }
  }

  ngAfterViewInit(): void {}

  private _validCollection(st: ExprSearch): any {
    st.validColl = st.cancerTypeSelected
      .map((val) => {
        return collectionList.expr_stage.collnames[collectionList.expr_stage.cancertypes.indexOf(val)];
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
          case 'GSVAStageImage':
            this.GSVAStageImage = reader.result;
            break;
          case 'GSVAStageTrendImage':
            this.GSVAStageTrendImage = reader.result;
            break;
          /* case 'GSVAStageSingleCancerImage':
            this.GSVAStageSingleCancerImage = reader.result;
            break; */
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
    this.dataSourceGSVAStage.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceGSVAStage.paginator) {
      this.dataSourceGSVAStage.paginator.firstPage();
    }
  }
  public exportExcel() {
    const workSheet = XLSX.utils.json_to_sheet(this.dataSourceGSVAStage.data, { header: this.displayedColumnsGSVAStage });
    const workBook: XLSX.WorkBook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workBook, workSheet, 'SheetName');
    XLSX.writeFile(workBook, 'GsvaStageTable.xlsx');
  }
  /* public expandDetail(element: GSVAStageTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.GSVAStageSingleCancerImageLoading = true;
      this.showGSVAStageSingleCancerImage = false;
      if (this.expandedColumn === 'cancertype') {
        this.expressionApiService.getGSVAStageSingleCancerImage(this.gsvaStageResourceUUID, this.expandedElement.cancertype).subscribe(
          (res) => {
            this.GSVAStageSingleCancerPdfURL = this.expressionApiService.getResourcePlotURL(res.gsvastagesinglecanceruuid, 'pdf');
            this.expressionApiService.getResourcePlotBlob(res.gsvastagesinglecanceruuid, 'png').subscribe(
              (r) => {
                this.showGSVAStageSingleCancerImage = true;
                this.GSVAStageSingleCancerImageLoading = false;
                this._createImageFromBlob(r, 'GSVAStageSingleCancerImage');
              },
              (e) => {
                this.showGSVAStageSingleCancerImage = false;
              }
            );
          },
          (err) => {
            this.showGSVAStageSingleCancerImage = false;
            this.GSVAStageSingleCancerImageLoading = false;
          }
        );
      }
    } else {
      this.GSVAStageSingleCancerImageLoading = false;
      this.showGSVAStageSingleCancerImage = false;
    }
  }

  public triggerDetail(element: GSVAStageTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  } */
}
