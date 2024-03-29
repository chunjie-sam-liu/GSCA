import { AfterViewInit, Component, ElementRef, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { MethySurvivalTableRecord } from 'src/app/shared/model/methysurvivaltablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { MutationApiService } from '../mutation-api.service';
import { animate, state, style, transition, trigger } from '@angular/animations';
import * as XLSX from 'xlsx';

@Component({
  selector: 'app-methy-survival',
  templateUrl: './methy-survival.component.html',
  styleUrls: ['./methy-survival.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class MethySurvivalComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // methy survival table data source
  dataSourceMethySurvivalLoading = true;
  dataSourceMethySurvival: MatTableDataSource<MethySurvivalTableRecord>;
  showMethySurvivalTable = true;
  @ViewChild('paginatorMethySurvival') paginatorMethySurvival: MatPaginator;
  @ViewChild(MatSort) sortMethySurvival: MatSort;
  displayedColumnsMethySurvival = ['cancertype', 'symbol', 'tag', 'sur_type', 'log_rank_p', 'cox_p', 'HR', 'higher_risk_of_death'];
  displayedColumnsMethySurvivalHeader = [
    'Cancer type',
    'Gene symbol',
    'Tag',
    'Survival type',
    'Logrank P value',
    'Cox P value',
    'Hazard Ratio',
    'Higher risk of death',
  ];
  expandedElement: MethySurvivalTableRecord;
  expandedColumn: string;

  // methy survival plot
  methySurvivalImageLoading = true;
  methySurvivalImage: any;
  showMethySurvivalImage = true;
  methySurvivalPdfURL: string;

  // single gene survival
  methySurvivalSingleGeneImage: any;
  methySurvivalSingleGeneImageLoading = false;
  showMethySurvivalSingleGeneImage = false;
  methySurvivalSingleGenePdfURL: string;

  constructor(private mutationApiService: MutationApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.dataSourceMethySurvivalLoading = true;
    this.methySurvivalImageLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceMethySurvivalLoading = false;
      this.methySurvivalImageLoading = false;
      this.showMethySurvivalTable = false;
      this.showMethySurvivalImage = false;
    } else {
      this.showMethySurvivalTable = true;
      this.mutationApiService.getMethySurvivalTable(postTerm).subscribe(
        (res) => {
          this.dataSourceMethySurvivalLoading = false;
          this.dataSourceMethySurvival = new MatTableDataSource(res);
          this.dataSourceMethySurvival.paginator = this.paginatorMethySurvival;
          this.dataSourceMethySurvival.sort = this.sortMethySurvival;
        },
        (err) => {
          this.dataSourceMethySurvivalLoading = false;
          this.showMethySurvivalTable = false;
        }
      );

      this.mutationApiService.getMethySurvivalPlot(postTerm).subscribe(
        (res) => {
          this.methySurvivalPdfURL = this.mutationApiService.getResourcePlotURL(res.methysurvivalplotuuid, 'pdf');
          this.mutationApiService.getResourcePlotBlob(res.methysurvivalplotuuid, 'png').subscribe(
            (r) => {
              this.showMethySurvivalImage = true;
              this.methySurvivalImageLoading = false;
              this._createImageFromBlob(r, 'methySurvivalImage');
            },
            (e) => {
              this.showMethySurvivalImage = false;
            }
          );
        },
        (err) => {
          this.showMethySurvivalImage = false;
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
          case 'methySurvivalImage':
            this.methySurvivalImage = reader.result;
            break;
          case 'methySurvivalSingleGeneImage':
            this.methySurvivalSingleGeneImage = reader.result;
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
        return collectionlist.methy_survival.collnames[collectionlist.methy_survival.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }
  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceMethySurvival.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceMethySurvival.paginator) {
      this.dataSourceMethySurvival.paginator.firstPage();
    }
  }

  public expandDetail(element: MethySurvivalTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.methySurvivalSingleGeneImageLoading = true;
      this.showMethySurvivalSingleGeneImage = false;
      if (this.expandedColumn === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [
            collectionlist.methy_survival.collnames[collectionlist.methy_survival.cancertypes.indexOf(this.expandedElement.cancertype)],
          ],
          surType: [this.expandedElement.sur_type],
        };

        this.mutationApiService.getMethySurvivalSingleGene(postTerm).subscribe(
          (res) => {
            this.methySurvivalSingleGenePdfURL = this.mutationApiService.getResourcePlotURL(res.methysurvivalsinglegeneuuid, 'pdf');
            this.mutationApiService.getResourcePlotBlob(res.methysurvivalsinglegeneuuid, 'png').subscribe(
              (r) => {
                this._createImageFromBlob(r, 'methySurvivalSingleGeneImage');
                this.methySurvivalSingleGeneImageLoading = false;
                this.showMethySurvivalSingleGeneImage = true;
              },
              (e) => {
                this.showMethySurvivalSingleGeneImage = false;
              }
            );
          },
          (err) => {
            this.showMethySurvivalSingleGeneImage = false;
          }
        );
      }
    } else {
      this.showMethySurvivalSingleGeneImage = false;
    }
  }
  public triggerDetail(element: MethySurvivalTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
  public exportExcel() {
    const workSheet = XLSX.utils.json_to_sheet(this.dataSourceMethySurvival.data, { header: this.displayedColumnsMethySurvival });
    const workBook: XLSX.WorkBook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workBook, workSheet, 'SheetName');
    XLSX.writeFile(workBook, 'MethylationAndSurvivalTable.xlsx');
  }
}
