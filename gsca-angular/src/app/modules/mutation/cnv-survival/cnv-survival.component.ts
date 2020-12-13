import { AfterViewInit, Component, ElementRef, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { CnvSurvivalTableRecord } from 'src/app/shared/model/cnvsurvivaltablerecord';
import { CnvGenesetSurvivalTableRecord } from 'src/app/shared/model/cnvgenesetsurvivaltablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { MutationApiService } from '../mutation-api.service';
import { animate, state, style, transition, trigger } from '@angular/animations';
import { timeout } from 'rxjs/operators';

@Component({
  selector: 'app-cnv-survival',
  templateUrl: './cnv-survival.component.html',
  styleUrls: ['./cnv-survival.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class CnvSurvivalComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // cnv table data source
  dataSourceCnvSurvivalLoading = true;
  dataSourceCnvSurvival: MatTableDataSource<CnvSurvivalTableRecord>;
  showCnvSurvivalTable = true;
  @ViewChild('paginatorCnvSurvival') paginatorCnvSurvival: MatPaginator;
  @ViewChild(MatSort) sortCnvSurvival: MatSort;
  displayedColumnsCnvSurvival = ['cancertype', 'symbol', 'sur_type', 'log_rank_p'];
  displayedColumnsCnvSurvivalHeader = ['Cancer type', 'Gene symbol', 'Survival type', 'Logrank P value'];
  expandedElement: CnvSurvivalTableRecord;
  expandedColumn: string;

  // cnv survival plot
  cnvSurvivalImageLoading = true;
  cnvSurvivalImage: any;
  showCnvSurvivalImage = true;
  cnvSurvivalPdfURL: string;

  // cnv single gene survival
  cnvSurvivalSingleGeneImage: any;
  cnvSurvivalSingleGeneImageLoading = true;
  showCnvSurvivalSingleGeneImage = false;
  cnvSurvivalSingleGenePdfURL: string;

  // cnv geneset survival plot
  showCnvGenesetSurvivalImage = true;
  cnvGenesetSurvivalImage: any;
  cnvGenesetSurvivalImageLoading = true;
  cnvGenesetSurvivalPdfURL: string;

  // cnv geneset survival table
  showCnvGenesetSurvivalTable = true;
  cnvGenesetSurvivalTable: MatTableDataSource<CnvGenesetSurvivalTableRecord>;
  cnvGenesetSurvivalTableLoading = true;
  @ViewChild('paginatorCnvGenesetSurvival') paginatorCnvGenesetSurvival: MatPaginator;
  @ViewChild(MatSort) sortCnvGenesetSurvival: MatSort;
  displayedColumnsCnvGenesetSurvival = ['cancertype', 'sur_type', 'logrankp'];
  displayedColumnsCnvGenesetSurvivalHeader = ['Cancer type', 'Survival type', 'Logrank P value'];
  expandedElementGeneset: CnvGenesetSurvivalTableRecord;
  expandedColumnGeneset: string;

  // cnv single cancertype survival
  cnvGenesetSurvivalSingleCancerImage: any;
  cnvGenesetSurvivalSingleCancerImageLoading = true;
  showCnvGenesetSurvivalSingleCancerImage = false;
  cnvGenesetSurvivalSingleCancerPdfURL: string;

  constructor(private mutationApiService: MutationApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.dataSourceCnvSurvivalLoading = true;
    this.cnvSurvivalImageLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceCnvSurvivalLoading = false;
      this.cnvSurvivalImageLoading = false;
      this.showCnvSurvivalTable = false;
      this.showCnvSurvivalImage = false;
      this.cnvGenesetSurvivalTableLoading = false;
      this.showCnvGenesetSurvivalTable = false;
    } else {
      this.showCnvSurvivalTable = true;
      this.showCnvGenesetSurvivalTable = true;
      this.showCnvGenesetSurvivalTable = true;
      this.mutationApiService.getCnvSurvivalTable(postTerm).subscribe(
        (res) => {
          this.dataSourceCnvSurvivalLoading = false;
          this.dataSourceCnvSurvival = new MatTableDataSource(res);
          this.dataSourceCnvSurvival.paginator = this.paginatorCnvSurvival;
          this.dataSourceCnvSurvival.sort = this.sortCnvSurvival;
        },
        (err) => {
          this.dataSourceCnvSurvivalLoading = false;
          this.showCnvSurvivalTable = false;
        }
      );

      this.mutationApiService.getCnvSurvivalPlot(postTerm).subscribe(
        (res) => {
          this.cnvSurvivalPdfURL = this.mutationApiService.getResourcePlotURL(res.cnvsurvivalplotuuid, 'pdf');
          this.mutationApiService.getResourcePlotBlob(res.cnvsurvivalplotuuid, 'png').subscribe(
            (r) => {
              this.showCnvSurvivalImage = true;
              this.cnvSurvivalImageLoading = false;
              this._createImageFromBlob(r, 'cnvSurvivalImage');
            },
            (e) => {
              this.cnvSurvivalImageLoading = false;
              this.showCnvSurvivalImage = false;
            }
          );
        },
        (err) => {
          this.cnvSurvivalImageLoading = false;
          this.showCnvSurvivalImage = false;
        }
      );

      this.mutationApiService.getCnvGenesetSurvivalPlot(postTerm).subscribe(
        (res) => {
          this.cnvGenesetSurvivalPdfURL = this.mutationApiService.getResourcePlotURL(res.cnvsurvivalgenesetuuid, 'pdf');
          this.mutationApiService.getResourcePlotBlob(res.cnvsurvivalgenesetuuid, 'png').subscribe(
            (r) => {
              this.showCnvGenesetSurvivalImage = true;
              this.cnvGenesetSurvivalImageLoading = false;
              this._createImageFromBlob(r, 'cnvGenesetSurvivalImage');
            },
            (e) => {
              this.showCnvGenesetSurvivalImage = false;
            }
          );
        },
        (err) => {
          this.showCnvGenesetSurvivalImage = false;
        }
      );

      this.mutationApiService
        .getCnvGenesetSurvivalTable(postTerm)
        .pipe(timeout(3000))
        .subscribe(
          (res) => {
            this.cnvGenesetSurvivalTableLoading = false;
            this.cnvGenesetSurvivalTable = new MatTableDataSource(res);
            this.cnvGenesetSurvivalTable.paginator = this.paginatorCnvGenesetSurvival;
            this.cnvGenesetSurvivalTable.sort = this.sortCnvGenesetSurvival;
          },
          (err) => {
            this.cnvGenesetSurvivalTableLoading = false;
            this.showCnvGenesetSurvivalTable = false;
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
          case 'cnvSurvivalImage':
            this.cnvSurvivalImage = reader.result;
            break;
          case 'cnvSurvivalSingleGeneImage':
            this.cnvSurvivalSingleGeneImage = reader.result;
            break;
          case 'cnvGenesetSurvivalImage':
            this.cnvGenesetSurvivalImage = reader.result;
            break;
          case 'cnvGenesetSurvivalSingleCancerImage':
            this.cnvGenesetSurvivalSingleCancerImage = reader.result;
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
        return collectionlist.cnv_survival.collnames[collectionlist.cnv_survival.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }
  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceCnvSurvival.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceCnvSurvival.paginator) {
      this.dataSourceCnvSurvival.paginator.firstPage();
    }
  }

  public expandDetail(element: CnvSurvivalTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.cnvSurvivalSingleGeneImageLoading = true;
      this.showCnvSurvivalSingleGeneImage = false;
      if (this.expandedColumn === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [
            collectionlist.cnv_threshold.collnames[collectionlist.cnv_threshold.cancertypes.indexOf(this.expandedElement.cancertype)],
          ],
          surType: [this.expandedElement.sur_type],
        };

        this.mutationApiService.getCnvSurvivalSingleGene(postTerm).subscribe(
          (res) => {
            this.cnvSurvivalSingleGenePdfURL = this.mutationApiService.getResourcePlotURL(res.cnvsurvivalsinglegeneuuid, 'pdf');
            this.mutationApiService.getResourcePlotBlob(res.cnvsurvivalsinglegeneuuid, 'png').subscribe(
              (r) => {
                this._createImageFromBlob(r, 'cnvSurvivalSingleGeneImage');
                this.cnvSurvivalSingleGeneImageLoading = false;
                this.showCnvSurvivalSingleGeneImage = true;
              },
              (e) => {
                this.showCnvSurvivalSingleGeneImage = false;
              }
            );
          },
          (err) => {
            this.showCnvSurvivalSingleGeneImage = false;
          }
        );
      }
    } else {
      this.showCnvSurvivalSingleGeneImage = false;
    }
  }
  public expandDetailGeneset(element: CnvGenesetSurvivalTableRecord, column: string): void {
    this.expandedElementGeneset = this.expandedElementGeneset === element && this.expandedColumnGeneset === column ? null : element;
    this.expandedColumnGeneset = column;

    if (this.expandedElementGeneset) {
      this.cnvGenesetSurvivalSingleCancerImageLoading = true;
      this.showCnvGenesetSurvivalSingleCancerImage = false;
      if (this.expandedColumnGeneset === 'cancertype') {
        const postTerm = {
          validSymbol: this.searchTerm.validSymbol,
          cancerTypeSelected: [this.expandedElementGeneset.cancertype],
          validColl: [
            collectionlist.cnv_survival.collnames[collectionlist.cnv_survival.cancertypes.indexOf(this.expandedElementGeneset.cancertype)],
          ],
          // tslint:disable-next-line: max-line-length
          // validColl: [collectionlist.cnv_survival.collnames[collectionlist.cnv_survival.cancertypes.//indexOf(this.expandedElementGeneset.cancertype)],],
          surType: [this.expandedElementGeneset.sur_type],
        };

        this.mutationApiService.getCnvGenesetSurvivalSingleCancer(postTerm).subscribe(
          (res) => {
            this.cnvGenesetSurvivalSingleCancerPdfURL = this.mutationApiService.getResourcePlotURL(
              res.cnvgenesetsurvivalsinglecanceruuid,
              'pdf'
            );
            this.mutationApiService.getResourcePlotBlob(res.cnvgenesetsurvivalsinglecanceruuid, 'png').subscribe(
              (r) => {
                this._createImageFromBlob(r, 'cnvGenesetSurvivalSingleCancerImage');
                this.cnvGenesetSurvivalSingleCancerImageLoading = false;
                this.showCnvGenesetSurvivalSingleCancerImage = true;
              },
              (e) => {
                this.showCnvGenesetSurvivalSingleCancerImage = false;
              }
            );
          },
          (err) => {
            this.showCnvGenesetSurvivalSingleCancerImage = false;
          }
        );
      }
    } else {
      this.showCnvGenesetSurvivalSingleCancerImage = false;
    }
  }
  public triggerDetail(element: CnvSurvivalTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
  public triggerDetailGeneset(element: CnvGenesetSurvivalTableRecord): string {
    return element === this.expandedElementGeneset ? 'expanded' : 'collapsed';
  }
}
