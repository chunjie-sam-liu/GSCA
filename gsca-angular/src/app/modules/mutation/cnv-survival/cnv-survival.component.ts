import { AfterViewInit, Component, ElementRef, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { CnvSurvivalTableRecord } from 'src/app/shared/model/cnvsurvivaltablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { MutationApiService } from '../mutation-api.service';
import { animate, state, style, transition, trigger } from '@angular/animations';
import { timeout } from 'rxjs/operators';
import * as XLSX from 'xlsx';

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
    } else {
      this.showCnvSurvivalTable = true;
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
  public triggerDetail(element: CnvSurvivalTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
  public exportExcel() {
    const workSheet = XLSX.utils.json_to_sheet(this.dataSourceCnvSurvival.data, { header: this.displayedColumnsCnvSurvival });
    const workBook: XLSX.WorkBook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workBook, workSheet, 'SheetName');
    XLSX.writeFile(workBook, 'CnvAndSurvivalTable.xlsx');
  }
}
