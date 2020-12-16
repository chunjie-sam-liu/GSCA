import { AfterViewInit, Component, ElementRef, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { SnvGenesetSurvivalTableRecord } from 'src/app/shared/model/snvgenesetsurvivaltablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { MutationApiService } from '../mutation-api.service';
import { animate, state, style, transition, trigger } from '@angular/animations';
import { timeout } from 'rxjs/operators';

@Component({
  selector: 'app-snv-geneset-survival',
  templateUrl: './snv-geneset-survival.component.html',
  styleUrls: ['./snv-geneset-survival.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class SnvGenesetSurvivalComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

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
    'Logrank P value',
    'Higher risk of death',
  ];
  expandedElementGeneset: SnvGenesetSurvivalTableRecord;
  expandedColumnGeneset: string;

  // geneset survival plot
  showSnvGenesetSurvivalImage = true;
  snvGenesetSurvivalImage: any;
  snvGenesetSurvivalImageLoading = true;
  snvGenesetSurvivalPdfURL: string;

  // single cancertype survival
  snvGenesetSurvivalSingleCancerImage: any;
  snvGenesetSurvivalSingleCancerImageLoading = true;
  showSnvGenesetSurvivalSingleCancerImage = false;
  snvGenesetSurvivalSingleCancerPdfURL: string;

  constructor(private mutationApiService: MutationApiService) {}
  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.snvGenesetSurvivalImageLoading = true;
    this.snvGenesetSurvivalTableLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.snvGenesetSurvivalTableLoading = false;
      this.showSnvGenesetSurvivalTable = false;
      this.showSnvGenesetSurvivalImage = false;
      this.snvGenesetSurvivalImageLoading = false;
    } else {
      this.mutationApiService.getGeneSetSNVAnalysis(postTerm).subscribe(
        (res) => {
          this.mutationApiService.getSnvGenesetSurvivalPlot(res.uuidname).subscribe(
            (snvgenesetres) => {
              this.showSnvGenesetSurvivalTable = true;
              this.mutationApiService
                .getResourceTable('preanalysised_snvgeneset_survival', snvgenesetres.snvsurvivalgenesettableuuid)
                .subscribe(
                  (r) => {
                    this.snvGenesetSurvivalTableLoading = false;
                    this.snvGenesetSurvivalTable = new MatTableDataSource(r);
                    this.snvGenesetSurvivalTable.paginator = this.paginatorSnvGenesetSurvival;
                    this.snvGenesetSurvivalTable.sort = this.sortSnvGenesetSurvival;
                  },
                  (e) => {
                    this.showSnvGenesetSurvivalTable = false;
                  }
                );
              this.snvGenesetSurvivalPdfURL = this.mutationApiService.getResourcePlotURL(snvgenesetres.snvsurvivalgenesetplotuuid, 'pdf');
              this.mutationApiService.getResourcePlotBlob(snvgenesetres.snvsurvivalgenesetplotuuid, 'png').subscribe(
                (r) => {
                  this.showSnvGenesetSurvivalImage = true;
                  this.snvGenesetSurvivalImageLoading = false;
                  this._createImageFromBlob(r, 'snvGenesetSurvivalImage');
                },
                (e) => {
                  this.showSnvGenesetSurvivalImage = false;
                }
              );
            },
            (e) => {
              this.showSnvGenesetSurvivalImage = false;
              this.showSnvGenesetSurvivalTable = false;
              this.snvGenesetSurvivalImageLoading = false;
              this.snvGenesetSurvivalTableLoading = false;
            }
          );
        },
        (err) => {}
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
          case 'snvGenesetSurvivalImage':
            this.snvGenesetSurvivalImage = reader.result;
            break;
          case 'snvGenesetSurvivalSingleCancerImage':
            this.snvGenesetSurvivalSingleCancerImage = reader.result;
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
    this.snvGenesetSurvivalTable.filter = filterValue.trim().toLowerCase();

    if (this.snvGenesetSurvivalTable.paginator) {
      this.snvGenesetSurvivalTable.paginator.firstPage();
    }
  }

  public expandDetailGeneset(element: SnvGenesetSurvivalTableRecord, column: string): void {
    this.expandedElementGeneset = this.expandedElementGeneset === element && this.expandedColumnGeneset === column ? null : element;
    this.expandedColumnGeneset = column;

    if (this.expandedElementGeneset) {
      this.snvGenesetSurvivalSingleCancerImageLoading = true;
      this.showSnvGenesetSurvivalSingleCancerImage = false;
      if (this.expandedColumnGeneset === 'cancertype') {
        const postTerm = {
          validSymbol: this.searchTerm.validSymbol,
          cancerTypeSelected: [this.expandedElementGeneset.cancertype],
          // validColl: this.searchTerm.validColl,
          // tslint:disable-next-line: max-line-length
          validColl: [
            collectionlist.snv_survival.collnames[collectionlist.snv_survival.cancertypes.indexOf(this.expandedElementGeneset.cancertype)],
          ],
          surType: [this.expandedElementGeneset.sur_type],
        };

        this.mutationApiService.getSnvGenesetSurvivalSingleCancer(postTerm).subscribe(
          (res) => {
            this.snvGenesetSurvivalSingleCancerPdfURL = this.mutationApiService.getResourcePlotURL(
              res.snvgenesetsurvivalsinglecanceruuid,
              'pdf'
            );
            this.mutationApiService.getResourcePlotBlob(res.snvgenesetsurvivalsinglecanceruuid, 'png').subscribe(
              (r) => {
                this._createImageFromBlob(r, 'snvGenesetSurvivalSingleCancerImage');
                this.snvGenesetSurvivalSingleCancerImageLoading = false;
                this.showSnvGenesetSurvivalSingleCancerImage = true;
              },
              (e) => {
                this.showSnvGenesetSurvivalSingleCancerImage = false;
              }
            );
          },
          (err) => {
            this.showSnvGenesetSurvivalSingleCancerImage = false;
          }
        );
      }
    } else {
      this.showSnvGenesetSurvivalSingleCancerImage = false;
    }
  }

  public triggerDetailGeneset(element: SnvGenesetSurvivalTableRecord): string {
    return element === this.expandedElementGeneset ? 'expanded' : 'collapsed';
  }
}
