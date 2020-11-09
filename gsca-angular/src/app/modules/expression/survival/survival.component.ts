import { AfterViewInit, Component, ElementRef, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { SurvivalTableRecord } from 'src/app/shared/model/survivaltablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { ExpressionApiService } from '../expression-api.service';
import { animate, state, style, transition, trigger } from '@angular/animations';

@Component({
  selector: 'app-survival',
  templateUrl: './survival.component.html',
  styleUrls: ['./survival.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class SurvivalComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // survival table data source
  dataSourceSurvivalLoading = true;
  dataSourceSurvival: MatTableDataSource<SurvivalTableRecord>;
  showSurvivalTable = true;
  @ViewChild('paginatorSurvival') paginatorSurvival: MatPaginator;
  @ViewChild(MatSort) sortSurvival: MatSort;
  displayedColumnsSurvival = ['cancertype', 'symbol', 'hr', 'pval', 'worse_group'];
  displayedColumnsSurvivalHeader = ['Cancer type', 'Gene symbol', 'Hazard Ratio', 'P value', 'Higher risk of death'];
  expandedElement: SurvivalTableRecord;
  expandedColumn: string;

  // survival plot
  survivalImageLoading = true;
  survivalImage: any;
  showSuvivalImage = true;

  // single gene
  survivalSingleGeneImage: any;
  survivalSingleGeneImageLoading = true;
  showSurvivalSingleGeneImage = false;

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.dataSourceSurvivalLoading = true;
    this.survivalImageLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceSurvivalLoading = false;
      this.survivalImageLoading = false;
      this.showSurvivalTable = false;
      this.showSuvivalImage = false;
    } else {
      this.showSurvivalTable = true;
      this.expressionApiService.getSurvivalTable(postTerm).subscribe(
        (res) => {
          this.dataSourceSurvivalLoading = false;
          this.dataSourceSurvival = new MatTableDataSource(res);
          this.dataSourceSurvival.paginator = this.paginatorSurvival;
          this.dataSourceSurvival.sort = this.sortSurvival;
        },
        (err) => {
          this.dataSourceSurvivalLoading = false;
          this.showSurvivalTable = false;
        }
      );

      this.expressionApiService.getSurvivalPlot(postTerm).subscribe(
        (res) => {
          this.showSuvivalImage = true;
          this.survivalImageLoading = false;
          this._createImageFromBlob(res, 'survivalImage');
        },
        (err) => {
          this.survivalImageLoading = false;
          this.showSuvivalImage = false;
        }
      );
    }
  }

  ngAfterViewInit(): void {
    // Called after ngAfterContentInit when the component's view has been initialized. Applies to components only.
    // Add 'implements AfterViewInit' to the class.
  }

  private _createImageFromBlob(res: Blob, present: string) {
    const reader = new FileReader();
    reader.addEventListener(
      'load',
      () => {
        switch (present) {
          case 'survivalImage':
            this.survivalImage = reader.result;
            break;
          case 'survivalSingleGeneImage':
            this.survivalSingleGeneImage = reader.result;
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
        return collectionlist.expr_survival.collnames[collectionlist.expr_survival.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }

  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceSurvival.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceSurvival.paginator) {
      this.dataSourceSurvival.paginator.firstPage();
    }
  }

  public expandDetail(element: SurvivalTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.survivalSingleGeneImageLoading = true;
      this.showSurvivalSingleGeneImage = false;
      if (this.expandedColumn === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [
            collectionlist.expr_survival.collnames[collectionlist.expr_survival.cancertypes.indexOf(this.expandedElement.cancertype)],
          ],
        };

        this.expressionApiService.getSurvivalSingleGenePlot(postTerm).subscribe(
          (res) => {
            this._createImageFromBlob(res, 'survivalSingleGeneImage');
            this.survivalSingleGeneImageLoading = false;
            this.showSurvivalSingleGeneImage = true;
          },
          (err) => {
            this.survivalSingleGeneImageLoading = false;
            this.showSurvivalSingleGeneImage = false;
          }
        );
      }
    } else {
      this.survivalSingleGeneImageLoading = false;
      this.showSurvivalSingleGeneImage = false;
    }
  }

  public triggerDetail(element: SurvivalTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
}
