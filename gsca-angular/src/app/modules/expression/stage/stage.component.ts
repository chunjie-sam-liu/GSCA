import { Component, Input, OnInit, ViewChild, OnChanges, SimpleChanges, AfterViewChecked } from '@angular/core';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { StageTableRecord } from 'src/app/shared/model/stagetablerecord';
import { ExpressionApiService } from '../expression-api.service';
import { animate, state, style, transition, trigger } from '@angular/animations';

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
  displayedColumnsStage = ['cancertype', 'symbol', 'pval', 'fdr'];
  displayedColumnsStageHeader = ['Cancer type', 'Gene symbol', 'P value', 'FDR'];
  expandedElement: StageTableRecord;
  expandedColumn: string;

  // stage image
  stageImageLoading = true;
  stageImage: any;
  showStageImage = true;

  // single gene
  stageSingleGeneImage: any;
  stageSingleGeneImageLoading = true;
  showStageSingleGeneImage = false;

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.stageImageLoading = true;
    this.stageTableLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.stageImageLoading = false;
      this.stageTableLoading = false;
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
          this.showStageImage = true;
          this.stageImageLoading = false;
          this._createImageFromBlob(res, 'stageImage');
        },
        (err) => {
          this.showStageImage = false;
          this.stageImageLoading = false;
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
        };

        this.expressionApiService.getStageSingleGenePlot(postTerm).subscribe(
          (res) => {
            this._createImageFromBlob(res, 'stageSingleGeneImage');
            this.stageSingleGeneImageLoading = false;
            this.showStageSingleGeneImage = true;
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
}
