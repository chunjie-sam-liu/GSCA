import { AfterViewInit, Component, ElementRef, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { MethyCorTableRecord } from 'src/app/shared/model/methycortablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { MutationApiService } from '../mutation-api.service';
import { animate, state, style, transition, trigger } from '@angular/animations';
import * as XLSX from 'xlsx';

@Component({
  selector: 'app-methy-cor',
  templateUrl: './methy-cor.component.html',
  styleUrls: ['./methy-cor.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class MethyCorComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // methy cor table data source
  dataSourceMethyCorLoading = true;
  dataSourceMethyCor: MatTableDataSource<MethyCorTableRecord>;
  showMethyCorTable = true;
  @ViewChild('paginatorMethyCor') paginatorMethyCor: MatPaginator;
  @ViewChild(MatSort) sortMethyCor: MatSort;
  displayedColumnsMethyCor = ['cancertype', 'symbol', 'spm', 'fdr'];
  displayedColumnsMethyCorHeader = ['Cancer type', 'Gene symbol', 'Spearman correlation', 'FDR'];
  expandedElement: MethyCorTableRecord;
  expandedColumn: string;

  // methy cor plot
  methyCorImageLoading = true;
  methyCorImage: any;
  showMethyCorImage = true;
  methyCorPdfURL: string;

  // single gene cor
  methyCorSingleGeneImage: any;
  methyCorSingleGeneImageLoading = true;
  showMethyCorSingleGeneImage = false;
  methyCorSingleGenePdfURL: string;

  constructor(private mutationApiService: MutationApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.dataSourceMethyCorLoading = true;
    this.methyCorImageLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceMethyCorLoading = false;
      this.methyCorImageLoading = false;
      this.showMethyCorTable = false;
      this.showMethyCorImage = false;
    } else {
      this.showMethyCorTable = true;
      this.mutationApiService.getMethyCorTable(postTerm).subscribe(
        (res) => {
          this.dataSourceMethyCorLoading = false;
          this.dataSourceMethyCor = new MatTableDataSource(res);
          this.dataSourceMethyCor.paginator = this.paginatorMethyCor;
          this.dataSourceMethyCor.sort = this.sortMethyCor;
        },
        (err) => {
          this.dataSourceMethyCorLoading = false;
          this.showMethyCorTable = false;
        }
      );

      this.mutationApiService.getMethyCorPlot(postTerm).subscribe(
        (res) => {
          this.methyCorPdfURL = this.mutationApiService.getResourcePlotURL(res.methycorplotuuid, 'pdf');
          this.mutationApiService.getResourcePlotBlob(res.methycorplotuuid, 'png').subscribe(
            (r) => {
              this.showMethyCorImage = true;
              this.methyCorImageLoading = false;
              this._createImageFromBlob(r, 'methyCorImage');
            },
            (e) => {
              this.showMethyCorImage = false;
            }
          );
        },
        (err) => {
          this.showMethyCorImage = false;
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
          case 'methyCorImage':
            this.methyCorImage = reader.result;
            break;
          case 'methyCorSingleGeneImage':
            this.methyCorSingleGeneImage = reader.result;
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
        return collectionlist.methy_cor_expr.collnames[collectionlist.methy_cor_expr.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }
  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceMethyCor.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceMethyCor.paginator) {
      this.dataSourceMethyCor.paginator.firstPage();
    }
  }

  public expandDetail(element: MethyCorTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.methyCorSingleGeneImageLoading = true;
      this.showMethyCorSingleGeneImage = false;
      if (this.expandedColumn === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [
            collectionlist.methy_cor_expr.collnames[collectionlist.methy_cor_expr.cancertypes.indexOf(this.expandedElement.cancertype)],
          ],
        };

        this.mutationApiService.getMethyCorSingleGene(postTerm).subscribe(
          (res) => {
            this.methyCorSingleGenePdfURL = this.mutationApiService.getResourcePlotURL(res.methyCorSingleGenePdfURL, 'pdf');
            this.mutationApiService.getResourcePlotBlob(res.methyCorSingleGenePdfURL, 'png').subscribe(
              (r) => {
                this._createImageFromBlob(r, 'methyCorSingleGeneImage');
                this.methyCorSingleGeneImageLoading = false;
                this.showMethyCorSingleGeneImage = true;
              },
              (e) => {
                this.showMethyCorSingleGeneImage = false;
              }
            );
          },
          (err) => {
            this.showMethyCorSingleGeneImage = false;
          }
        );
      }
    } else {
      this.showMethyCorSingleGeneImage = false;
    }
  }
  public triggerDetail(element: MethyCorTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
  public exportExcel() {
    const workSheet = XLSX.utils.json_to_sheet(this.dataSourceMethyCor.data, { header: this.displayedColumnsMethyCor });
    const workBook: XLSX.WorkBook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workBook, workSheet, 'SheetName');
    XLSX.writeFile(workBook, 'ExpressionAndMethylationTable.xlsx');
  }
}
