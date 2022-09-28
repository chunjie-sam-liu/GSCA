import { AfterViewInit, Component, ElementRef, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { MethyTableRecord } from 'src/app/shared/model/methytablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { MutationApiService } from '../mutation-api.service';
import { animate, state, style, transition, trigger } from '@angular/animations';
import * as XLSX from 'xlsx';

@Component({
  selector: 'app-methylation',
  templateUrl: './methylation.component.html',
  styleUrls: ['./methylation.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class MethylationComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;
  // DE methylation table data source
  dataSourceMethyLoading = true;
  dataSourceMethy: MatTableDataSource<MethyTableRecord>;
  showMethyTable = true;
  @ViewChild('paginatorMethy') paginatorMethy: MatPaginator;
  @ViewChild(MatSort) sortMethy: MatSort;
  displayedColumnsMethy = ['cancertype', 'symbol', 'gene_tag', 'fc', 'trend', 'pval', 'fdr'];
  displayedColumnsMethyHeader = ['Cancer type', 'Gene symbol', 'Tag', 'Methylation (Tumor-Normal)', 'Trend', 'P value', 'FDR'];
  expandedElement: MethyTableRecord;
  expandedColumn: string;
  validCancertype: string;

  // DE methylation plot
  methyImageLoading = true;
  methyImage: any;
  showMethyImage = true;
  methyImagePdfURL: string;

  // DE methylation single gene
  methySingleGeneImage: any;
  methySingleGeneImageLoading = false;
  showMethySingleGeneImage = false;
  methySingleGenePdfURL: string;

  // DE methylation single cancer
  methySingleCancerImage: any;
  methySingleCancerImageLoading = false;
  showMethySingleCancerImage = false;
  methySingleCancerPdfURL: string;

  constructor(private mutationApiService: MutationApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.dataSourceMethyLoading = true;
    this.methyImageLoading = true;

    const postTerm = this._validCollection(this.searchTerm);
    this.validCancertype = this._validCancer(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceMethyLoading = false;
      this.methyImageLoading = false;
      this.showMethyTable = false;
      this.showMethyImage = false;
    } else {
      // get methyTable
      this.showMethyTable = true;
      this.mutationApiService.getMethyDeTable(postTerm).subscribe(
        (res) => {
          this.dataSourceMethyLoading = false;
          this.dataSourceMethy = new MatTableDataSource(res);
          this.dataSourceMethy.paginator = this.paginatorMethy;
          this.dataSourceMethy.sort = this.sortMethy;
        },
        (err) => {
          this.dataSourceMethyLoading = false;
          this.showMethyTable = false;
        }
      );
      // get methyPlot
      this.mutationApiService.getMethyDePlot(postTerm).subscribe(
        (res) => {
          this.methyImagePdfURL = this.mutationApiService.getResourcePlotURL(res.methyDiffuuid, 'pdf');
          this.mutationApiService.getResourcePlotBlob(res.methyDiffuuid, 'png').subscribe(
            (r) => {
              this.showMethyImage = true;
              this.methyImageLoading = false;
              this._createImageFromBlob(r, 'methyImage');
            },
            (e) => {
              this.showMethyImage = false;
            }
          );
        },
        (err) => {
          this.showMethyImage = false;
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
          case 'methyImage':
            this.methyImage = reader.result;
            break;
          case 'methySingleGeneImage':
            this.methySingleGeneImage = reader.result;
            break;
          case 'methySingleCancerImage':
            this.methySingleCancerImage = reader.result;
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
        return collectionlist.methy_diff.collnames[collectionlist.methy_diff.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }
  private _validCancer(st: ExprSearch): any {
    const validCancer = st.cancerTypeSelected
      .map((val) => {
        return collectionlist.methy_diff.cancertypes[collectionlist.methy_diff.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return validCancer;
  }
  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceMethy.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceMethy.paginator) {
      this.dataSourceMethy.paginator.firstPage();
    }
  }
  public expandDetail(element: MethyTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.methySingleGeneImageLoading = true;
      this.showMethySingleGeneImage = false;
      this.methySingleCancerImageLoading = true;
      this.showMethySingleCancerImage = false;
      if (this.expandedColumn === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: collectionlist.all_methy.cancertypes,
          validColl: collectionlist.all_methy.collnames,
        };

        this.mutationApiService.getSingleGeneMethyDE(postTerm).subscribe(
          (res) => {
            this.methySingleGenePdfURL = this.mutationApiService.getResourcePlotURL(res.singleGeneMethyDiffuuid, 'pdf');
            this.mutationApiService.getResourcePlotBlob(res.singleGeneMethyDiffuuid, 'png').subscribe(
              (r) => {
                this._createImageFromBlob(r, 'methySingleGeneImage');
                this.methySingleGeneImageLoading = false;
                this.showMethySingleGeneImage = true;
                this.methySingleCancerImageLoading = false;
                this.showMethySingleCancerImage = false;
              },
              (e) => {
                this.methySingleGeneImageLoading = false;
                this.showMethySingleGeneImage = false;
                this.methySingleCancerImageLoading = false;
                this.showMethySingleCancerImage = false;
              }
            );
          },
          (err) => {
            this.methySingleGeneImageLoading = false;
            this.showMethySingleGeneImage = false;
            this.methySingleCancerImageLoading = false;
            this.showMethySingleCancerImage = false;
          }
        );
      }
      if (this.expandedColumn === 'cancertype') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [collectionlist.all_methy.collnames[collectionlist.all_methy.cancertypes.indexOf(this.expandedElement.cancertype)]],
        };

        this.mutationApiService.getSingleCancerMethyDE(postTerm).subscribe(
          (res) => {
            this.methySingleCancerPdfURL = this.mutationApiService.getResourcePlotURL(res.singleCancerMethyDiffuuid, 'pdf');
            this.mutationApiService.getResourcePlotBlob(res.singleCancerMethyDiffuuid, 'png').subscribe(
              (r) => {
                this._createImageFromBlob(r, 'methySingleCancerImage');
                this.methySingleGeneImageLoading = false;
                this.showMethySingleGeneImage = false;
                this.methySingleCancerImageLoading = false;
                this.showMethySingleCancerImage = true;
              },
              (e) => {
                this.methySingleGeneImageLoading = false;
                this.showMethySingleGeneImage = false;
                this.methySingleCancerImageLoading = false;
                this.showMethySingleCancerImage = false;
              }
            );
          },
          (err) => {
            this.methySingleGeneImageLoading = false;
            this.showMethySingleGeneImage = false;
            this.methySingleCancerImageLoading = false;
            this.showMethySingleCancerImage = false;
          }
        );
      }
    } else {
      this.methySingleGeneImageLoading = false;
      this.showMethySingleGeneImage = false;
      this.methySingleCancerImageLoading = false;
      this.showMethySingleCancerImage = false;
    }
  }

  public triggerDetail(element: MethyTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
  public exportExcel() {
    const workSheet = XLSX.utils.json_to_sheet(this.dataSourceMethy.data, { header: this.displayedColumnsMethy });
    const workBook: XLSX.WorkBook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workBook, workSheet, 'SheetName');
    XLSX.writeFile(workBook, 'DifferentialMethylationTable.xlsx');
  }
}
