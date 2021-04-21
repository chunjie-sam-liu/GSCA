import { AfterViewInit, Component, ElementRef, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { CnvGenesetSurvivalTableRecord } from 'src/app/shared/model/cnvgenesetsurvivaltablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { MutationApiService } from '../mutation-api.service';
import { animate, state, style, transition, trigger } from '@angular/animations';
import * as XLSX from 'xlsx';

@Component({
  selector: 'app-cnv-geneset-survival',
  templateUrl: './cnv-geneset-survival.component.html',
  styleUrls: ['./cnv-geneset-survival.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class CnvGenesetSurvivalComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // geneset survival plot
  showCnvGenesetSurvivalTable = true;
  cnvGenesetSurvivalTable: MatTableDataSource<CnvGenesetSurvivalTableRecord>;
  cnvGenesetSurvivalTableLoading = true;
  @ViewChild('paginatorCnvGenesetSurvival') paginatorCnvGenesetSurvival: MatPaginator;
  @ViewChild(MatSort) sortCnvGenesetSurvival: MatSort;
  displayedColumnsCnvGenesetSurvival = ['cancertype', 'sur_type', 'logrankp'];
  displayedColumnsCnvGenesetSurvivalHeader = ['Cancer type', 'Survival type', 'Logrank P value'];
  expandedElement: CnvGenesetSurvivalTableRecord;
  expandedColumn: string;

  // geneset survival plot
  showCnvGenesetSurvivalImage = true;
  cnvGenesetSurvivalImage: any;
  cnvGenesetSurvivalImageLoading = true;
  cnvGenesetSurvivalPdfURL: string;

  // single cancertype survival
  cnvGenesetSurvivalResourceUUID: string;
  cnvGenesetSurvivalSingleCancerImage: any;
  cnvGenesetSurvivalSingleCancerImageLoading = true;
  showCnvGenesetSurvivalSingleCancerImage = false;
  cnvGenesetSurvivalSingleCancerPdfURL: string;

  constructor(private mutationApiService: MutationApiService) {}
  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.cnvGenesetSurvivalImageLoading = true;
    this.cnvGenesetSurvivalTableLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.cnvGenesetSurvivalTableLoading = false;
      this.showCnvGenesetSurvivalTable = false;
      this.showCnvGenesetSurvivalImage = false;
      this.cnvGenesetSurvivalImageLoading = false;
    } else {
      this.mutationApiService.getGeneSetCNVAnalysis(postTerm).subscribe(
        (res) => {
          this.cnvGenesetSurvivalResourceUUID = res.uuidname;
          this.mutationApiService.getCnvGenesetSurvivalPlot(res.uuidname).subscribe(
            (cnvgenesetres) => {
              this.showCnvGenesetSurvivalTable = true;
              this.mutationApiService
                .getResourceTable('preanalysised_cnvgeneset_survival', cnvgenesetres.cnvsurvivalgenesettableuuid)
                .subscribe(
                  (r) => {
                    this.cnvGenesetSurvivalTableLoading = false;
                    this.cnvGenesetSurvivalTable = new MatTableDataSource(r);
                    this.cnvGenesetSurvivalTable.paginator = this.paginatorCnvGenesetSurvival;
                    this.cnvGenesetSurvivalTable.sort = this.sortCnvGenesetSurvival;
                  },
                  (e) => {
                    this.showCnvGenesetSurvivalTable = false;
                  }
                );
              this.cnvGenesetSurvivalPdfURL = this.mutationApiService.getResourcePlotURL(cnvgenesetres.cnvsurvivalgenesetplotuuid, 'pdf');
              this.mutationApiService.getResourcePlotBlob(cnvgenesetres.cnvsurvivalgenesetplotuuid, 'png').subscribe(
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
            (e) => {
              this.showCnvGenesetSurvivalImage = false;
              this.showCnvGenesetSurvivalTable = false;
              this.cnvGenesetSurvivalImageLoading = false;
              this.cnvGenesetSurvivalTableLoading = false;
            }
          );
        },
        (err) => {
          this.showCnvGenesetSurvivalImage = false;
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
    this.cnvGenesetSurvivalTable.filter = filterValue.trim().toLowerCase();

    if (this.cnvGenesetSurvivalTable.paginator) {
      this.cnvGenesetSurvivalTable.paginator.firstPage();
    }
  }

  public expandDetail(element: CnvGenesetSurvivalTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.cnvGenesetSurvivalSingleCancerImageLoading = true;
      this.showCnvGenesetSurvivalSingleCancerImage = false;
      if (this.expandedColumn === 'cancertype') {
        this.mutationApiService
          .getCnvGenesetSurvivalSingleCancer(
            this.cnvGenesetSurvivalResourceUUID,
            this.expandedElement.cancertype,
            this.expandedElement.sur_type
          )
          .subscribe(
            (res) => {
              this.cnvGenesetSurvivalSingleCancerPdfURL = this.mutationApiService.getResourcePlotURL(
                res.cnvgenesetsurvivalsinglecanceruuid,
                'pdf'
              );
              this.mutationApiService.getResourcePlotBlob(res.cnvgenesetsurvivalsinglecanceruuid, 'png').subscribe(
                (r) => {
                  this.cnvGenesetSurvivalSingleCancerImageLoading = false;
                  this.showCnvGenesetSurvivalSingleCancerImage = true;
                  this._createImageFromBlob(r, 'cnvGenesetSurvivalSingleCancerImage');
                },
                (e) => {
                  this.showCnvGenesetSurvivalSingleCancerImage = false;
                }
              );
            },
            (err) => {
              this.showCnvGenesetSurvivalSingleCancerImage = false;
              this.cnvGenesetSurvivalSingleCancerImageLoading = false;
            }
          );
      }
    } else {
      this.showCnvGenesetSurvivalSingleCancerImage = false;
      this.cnvGenesetSurvivalSingleCancerImageLoading = false;
    }
  }

  public triggerDetail(element: CnvGenesetSurvivalTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
  public exportExcel() {
    const workSheet = XLSX.utils.json_to_sheet(this.cnvGenesetSurvivalTable.data, { header: this.displayedColumnsCnvGenesetSurvival });
    const workBook: XLSX.WorkBook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workBook, workSheet, 'SheetName');
    XLSX.writeFile(workBook, 'GeneSetCnvSurvivalTable.xlsx');
  }
}
