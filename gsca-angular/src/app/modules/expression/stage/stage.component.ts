import { Component, Input, OnInit, ViewChild, OnChanges, SimpleChanges, AfterViewChecked } from '@angular/core';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { StageTableRecord } from 'src/app/shared/model/stagetablerecord';
import { ExpressionApiService } from '../expression-api.service';
import { animate, state, style, transition, trigger } from '@angular/animations';
import * as XLSX from 'xlsx';
@Component({
  selector: 'app-stage',
  templateUrl: './stage.component.html',
  styleUrls: ['./stage.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class StageComponent implements OnInit, OnChanges, AfterViewChecked {
  @Input() searchTerm: ExprSearch;

  // stage table
  stageTableLoading = true;
  stageTable: MatTableDataSource<StageTableRecord>;
  showStageTable = true;
  @ViewChild('paginatorStage') paginatorStage: MatPaginator;
  @ViewChild(MatSort) sortStage: MatSort;
  displayedColumnsStage = ['cancertype', 'symbol', 'stagetype', 'stage1', 'stage2', 'stage3', 'stage4', 'pval', 'fdr'];
  displayedColumnsStageHeader = [
    'Cancer type',
    'Gene symbol',
    'Stage type',
    'Stage I (mean expr./n)',
    'Stage II (mean expr./n)',
    'Stage III (mean expr./n)',
    'Stage IV (mean expr./n)',
    'P value',
    'FDR',
  ];
  expandedElement: StageTableRecord;
  expandedColumn: string;

  // stage image
  stageImageLoading = true;
  stageImage: any;
  showStageImage = true;
  stageImagePdfURL: string;

  // stage heat image
  stageHeatImageLoading = true;
  stageHeatImage: any;
  showStageHeatImage = true;
  stageHeatImagePdfURL: string;

  // stage trend image
  stageTrendImageLoading = true;
  stageTrendImage: any;
  showStageTrendImage = true;
  stageTrendImagePdfURL: string;

  // single gene
  stageSingleGeneImage: any;
  stageSingleGeneImageLoading = true;
  showStageSingleGeneImage = false;
  stageSingleGenePdfURL: string;
  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.stageImageLoading = true;
    this.stageTableLoading = true;
    this.stageHeatImageLoading = true;
    this.stageTrendImageLoading = true;
    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.stageImageLoading = false;
      this.stageTableLoading = false;
      this.stageHeatImageLoading = false;
      this.stageTrendImageLoading = false;
      this.showStageHeatImage = false;
      this.showStageTrendImage = false;
      this.showStageImage = false;
      this.showStageTable = false;
    } else {
      this.showStageTable = true;
      this.expressionApiService.getStageTable(postTerm).subscribe(
        (res) => {
          this.stageTableLoading = false;
          this.stageTable = new MatTableDataSource(res);
          this.stageTable.paginator = this.paginatorStage;
          this.stageTable.sort = this.sortStage;
        },
        (err) => {
          this.showStageTable = false;
          this.stageTableLoading = false;
        }
      );
      this.expressionApiService.getStagePlot(postTerm).subscribe(
        (res) => {
          // stage point
          this.stageImagePdfURL = this.expressionApiService.getResourcePlotURL(res.stagePointuuid, 'pdf');
          this.expressionApiService.getResourcePlotBlob(res.stagePointuuid, 'png').subscribe(
            (r) => {
              this.showStageImage = true;
              this.stageImageLoading = false;
              this._createImageFromBlob(r, 'stageImage');
            },
            (e) => {
              this.showStageImage = false;
            }
          );
        },
        (err) => {
          this.showStageImage = false;
        }
      );
      this.expressionApiService.getStageHeatTrendPlot(postTerm).subscribe(
        (res) => {
          // stage heatmap
          this.stageHeatImagePdfURL = this.expressionApiService.getResourcePlotURL(res.stageHeatuuid, 'pdf');
          this.expressionApiService.getResourcePlotBlob(res.stageHeatuuid, 'png').subscribe(
            (r) => {
              this.showStageHeatImage = true;
              this.stageHeatImageLoading = false;
              this._createImageFromBlob(r, 'stageHeatImage');
            },
            (e) => {
              this.showStageHeatImage = false;
            }
          );
          // stage trend
          this.stageTrendImagePdfURL = this.expressionApiService.getResourcePlotURL(res.stageTrenduuid, 'pdf');
          this.expressionApiService.getResourcePlotBlob(res.stageTrenduuid, 'png').subscribe(
            (r) => {
              this.showStageTrendImage = true;
              this.stageTrendImageLoading = false;
              this._createImageFromBlob(r, 'stageTrendImage');
            },
            (e) => {
              this.showStageTrendImage = false;
            }
          );
        },
        (err) => {
          this.showStageHeatImage = false;
          this.showStageTrendImage = false;
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
          case 'stageImage':
            this.stageImage = reader.result;
            break;
          case 'stageHeatImage':
            this.stageHeatImage = reader.result;
            break;
          case 'stageTrendImage':
            this.stageTrendImage = reader.result;
            break;
          case 'stageSingleGeneImage':
            this.stageSingleGeneImage = reader.result;
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
        return collectionlist.expr_stage.collnames[collectionlist.expr_stage.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }

  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.stageTable.filter = filterValue.trim().toLowerCase();

    if (this.stageTable.paginator) {
      this.stageTable.paginator.firstPage();
    }
  }

  public expandDetail(element: StageTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.stageSingleGeneImageLoading = true;
      this.showStageSingleGeneImage = false;
      if (this.expandedColumn === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [collectionlist.expr_stage.collnames[collectionlist.expr_stage.cancertypes.indexOf(this.expandedElement.cancertype)]],
          surType: [this.expandedElement.stagetype],
        };

        this.expressionApiService.getStageSingleGenePlot(postTerm).subscribe(
          (res) => {
            this.stageSingleGenePdfURL = this.expressionApiService.getResourcePlotURL(res.stagesinglegeneuuid, 'pdf');
            this.expressionApiService.getResourcePlotBlob(res.stagesinglegeneuuid, 'png').subscribe(
              (r) => {
                this._createImageFromBlob(r, 'stageSingleGeneImage');
                this.stageSingleGeneImageLoading = false;
                this.showStageSingleGeneImage = true;
              },
              (e) => {
                this.stageSingleGeneImageLoading = false;
                this.showStageSingleGeneImage = false;
              }
            );
          },
          (err) => {
            this.stageSingleGeneImageLoading = false;
            this.showStageSingleGeneImage = false;
          }
        );
      }
    } else {
      this.stageSingleGeneImageLoading = false;
      this.showStageSingleGeneImage = false;
    }
  }

  public triggerDetail(element: StageTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
  public exportExcel() {
    const workSheet = XLSX.utils.json_to_sheet(this.stageTable.data, { header: this.displayedColumnsStage });
    const workBook: XLSX.WorkBook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workBook, workSheet, 'SheetName');
    XLSX.writeFile(workBook, 'ExpressionAndStageTable.xlsx');
  }
}
