import { AfterViewInit, Component, ElementRef, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { SnvSurvivalTableRecord } from 'src/app/shared/model/snvsurvivaltablerecord';
import { SnvGenesetSurvivalTableRecord } from 'src/app/shared/model/snvgenesetsurvivaltablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { MutationApiService } from '../mutation-api.service';
import { animate, state, style, transition, trigger } from '@angular/animations';
import { timeout } from 'rxjs/operators';

@Component({
  selector: 'app-snv-survival',
  templateUrl: './snv-survival.component.html',
  styleUrls: ['./snv-survival.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class SnvSurvivalComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // snv table data source
  dataSourceSnvSurvivalLoading = true;
  dataSourceSnvSurvival: MatTableDataSource<SnvSurvivalTableRecord>;
  showSnvSurvivalTable = true;
  @ViewChild('paginatorSnvSurvival') paginatorSnvSurvival: MatPaginator;
  @ViewChild(MatSort) sortSnvSurvival: MatSort;
  displayedColumnsSnvSurvival = ['cancertype', 'symbol', 'sur_type', 'hr', 'cox_p', 'log_rank_p', 'higher_risk_of_death'];
  displayedColumnsSnvSurvivalHeader = [
    'Cancer type',
    'Gene symbol',
    'Survival type',
    'Hazard Ratio',
    'Cox P value',
    'Log rank P value',
    'Higher risk of death',
  ];
  expandedElement: SnvSurvivalTableRecord;
  expandedColumn: string;

  // snv survival plot
  snvSurvivalImageLoading = true;
  snvSurvivalImage: any;
  showSnvSurvivalImage = true;

  // single gene survival
  snvSurvivalSingleGeneImage: any;
  snvSurvivalSingleGeneImageLoading = true;
  showSnvSurvivalSingleGeneImage = false;

  // geneset survival plot
  showSnvGenesetSurvivalImage = true;
  snvGenesetSurvivalImage: any;
  snvGenesetSurvivalImageLoading = true;

  // geneset survival plot
  showSnvGenesetSurvivalTable = true;
  snvGenesetSurvivalTable: MatTableDataSource<SnvGenesetSurvivalTableRecord>;
  snvGenesetSurvivalTableLoading = true;
  @ViewChild('paginatorSnvGenesetSurvival') paginatorSnvGenesetSurvival: MatPaginator;
  @ViewChild(MatSort) sortSnvGenesetSurvival: MatSort;
  displayedColumnsSnvGenesetSurvival = ['cancertype', 'sur_type', 'hr', 'cox_p', 'logrankp', 'higher_risk_of_death'];
  displayedColumnsSnvGenesetSurvivalHeader = [
    'Cancer type',
    'Survival type',
    'Hazard Ratio',
    'Cox P value',
    'Log rank P value',
    'Higher risk of death',
  ];
  expandedElementGeneset: SnvGenesetSurvivalTableRecord;
  expandedColumnGeneset: string;

  // single cancertype survival
  snvGenesetSurvivalSingleCancerImage: any;
  snvGenesetSurvivalSingleCancerImageLoading = true;
  showSnvGenesetSurvivalSingleCancerImage = false;

  constructor(private mutationApiService: MutationApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.dataSourceSnvSurvivalLoading = true;
    this.snvSurvivalImageLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceSnvSurvivalLoading = false;
      this.snvSurvivalImageLoading = false;
      this.showSnvSurvivalTable = false;
      this.showSnvSurvivalImage = false;
      this.snvGenesetSurvivalTableLoading = false;
      this.showSnvGenesetSurvivalTable = false;
    } else {
      this.showSnvSurvivalTable = true;
      this.showSnvGenesetSurvivalTable = true;
      this.mutationApiService.getSnvSurvivalTable(postTerm).subscribe(
        (res) => {
          this.dataSourceSnvSurvivalLoading = false;
          this.dataSourceSnvSurvival = new MatTableDataSource(res);
          this.dataSourceSnvSurvival.paginator = this.paginatorSnvSurvival;
          this.dataSourceSnvSurvival.sort = this.sortSnvSurvival;
        },
        (err) => {
          this.dataSourceSnvSurvivalLoading = false;
          this.showSnvSurvivalTable = false;
        }
      );

      this.mutationApiService.getSnvSurvivalPlot(postTerm).subscribe(
        (res) => {
          this.showSnvSurvivalImage = true;
          this.snvSurvivalImageLoading = false;
          this._createImageFromBlob(res, 'snvSurvivalImage');
        },
        (err) => {
          this.snvSurvivalImageLoading = false;
          this.showSnvSurvivalImage = false;
        }
      );

      this.mutationApiService.getSnvGenesetSurvivalPlot(postTerm).subscribe(
        (res) => {
          this.showSnvGenesetSurvivalImage = true;
          this.snvGenesetSurvivalImageLoading = false;
          this._createImageFromBlob(res, 'snvGenesetSurvivalImage');
        },
        (err) => {
          this.snvGenesetSurvivalImageLoading = false;
          this.showSnvGenesetSurvivalImage = false;
        }
      );
      this.showSnvGenesetSurvivalTable = true;
      this.mutationApiService
        .getSnvGenesetSurvivalTable(postTerm)
        .pipe(timeout(3000))
        .subscribe(
          (res) => {
            this.snvGenesetSurvivalTableLoading = false;
            this.snvGenesetSurvivalTable = new MatTableDataSource(res);
            this.snvGenesetSurvivalTable.paginator = this.paginatorSnvGenesetSurvival;
            this.snvGenesetSurvivalTable.sort = this.sortSnvGenesetSurvival;
          },
          (err) => {
            this.snvGenesetSurvivalTableLoading = false;
            this.showSnvGenesetSurvivalTable = false;
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
          case 'snvSurvivalImage':
            this.snvSurvivalImage = reader.result;
            break;
          case 'snvSurvivalSingleGeneImage':
            this.snvSurvivalSingleGeneImage = reader.result;
            break;
          case 'snvGenesetSurvivalImage':
            this.snvGenesetSurvivalImage = reader.result;
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
        return collectionlist.snv_survival.collnames[collectionlist.snv_survival.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }
  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceSnvSurvival.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceSnvSurvival.paginator) {
      this.dataSourceSnvSurvival.paginator.firstPage();
    }
  }

  public expandDetail(element: SnvSurvivalTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.snvSurvivalSingleGeneImageLoading = true;
      this.showSnvSurvivalSingleGeneImage = false;
      if (this.expandedColumn === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [
            collectionlist.snv_survival.collnames[collectionlist.snv_survival.cancertypes.indexOf(this.expandedElement.cancertype)],
          ],
          surType: [this.expandedElement.sur_type],
        };

        this.mutationApiService.getSnvSurvivalSingleGene(postTerm).subscribe(
          (res) => {
            this._createImageFromBlob(res, 'snvSurvivalSingleGeneImage');
            this.snvSurvivalSingleGeneImageLoading = false;
            this.showSnvSurvivalSingleGeneImage = true;
          },
          (err) => {
            this.snvSurvivalSingleGeneImageLoading = false;
            this.showSnvSurvivalSingleGeneImage = false;
          }
        );
      }
    } else {
      this.snvSurvivalSingleGeneImageLoading = false;
      this.showSnvSurvivalSingleGeneImage = false;
    }
  }
  public expandDetailGeneset(element: SnvGenesetSurvivalTableRecord, column: string): void {
    this.expandedElementGeneset = this.expandedElementGeneset === element && this.expandedColumnGeneset === column ? null : element;
    this.expandedColumnGeneset = column;

    if (this.expandedElementGeneset) {
      this.snvGenesetSurvivalSingleCancerImageLoading = true;
      this.showSnvGenesetSurvivalSingleCancerImage = false;
      if (this.expandedColumnGeneset === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElementGeneset.cancertype],
          validColl: this.searchTerm.validColl,
          // tslint:disable-next-line: max-line-length
          // validColl: [collectionlist.snv_survival.collnames[collectionlist.snv_survival.cancertypes.//indexOf(this.expandedElementGeneset.cancertype)],],
          surType: [this.expandedElementGeneset.sur_type],
        };

        this.mutationApiService.getSnvGenesetSurvivalSingleCancer(postTerm).subscribe(
          (res) => {
            this._createImageFromBlob(res, 'snvGenesetSurvivalSingleCancerImage');
            this.snvGenesetSurvivalSingleCancerImageLoading = false;
            this.showSnvGenesetSurvivalSingleCancerImage = true;
          },
          (err) => {
            this.snvGenesetSurvivalSingleCancerImageLoading = false;
            this.showSnvGenesetSurvivalSingleCancerImage = false;
          }
        );
      }
    } else {
      this.snvGenesetSurvivalSingleCancerImageLoading = false;
      this.showSnvGenesetSurvivalSingleCancerImage = false;
    }
  }
  public triggerDetail(element: SnvSurvivalTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
}
