import { Component, Input, OnInit, ViewChild, OnChanges, SimpleChanges, AfterViewChecked } from '@angular/core';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { SubtypeTableRecord } from 'src/app/shared/model/subtypetablerecord';
import { ExpressionApiService } from '../expression-api.service';
import { animate, state, style, transition, trigger } from '@angular/animations';
import * as XLSX from 'xlsx';
@Component({
  selector: 'app-subtype',
  templateUrl: './subtype.component.html',
  styleUrls: ['./subtype.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class SubtypeComponent implements OnInit, OnChanges, AfterViewChecked {
  @Input() searchTerm: ExprSearch;

  // subtype table
  subtypeTableLoading = true;
  subtypeTable: MatTableDataSource<SubtypeTableRecord>;
  showSubtypeTable = true;
  @ViewChild('paginatorSubtype') paginatorSubtype: MatPaginator;
  @ViewChild(MatSort) sortSubtype: MatSort;
  displayedColumnsSubtype = ['cancertype', 'symbol', 'pval', 'fdr'];
  displayedColumnsSubtypeHeader = ['Cancer type', 'Gene symbol', 'P value', 'FDR'];
  expandedElement: SubtypeTableRecord;
  expandedColumn: string;

  // subtype image
  subtypeImageLoading = true;
  subtypeImage: any;
  showSubtypeImage = true;
  subtypeImagePdfURL: string;

  // single gene
  subtypeSingleGeneImage: any;
  subtypeSingleGeneImageLoading = true;
  showSubtypeSingleGeneImage = false;
  subtypeSingleGenePdfURL: string;

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.subtypeImageLoading = true;
    this.subtypeTableLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.subtypeImageLoading = false;
      this.subtypeTableLoading = false;
      this.showSubtypeImage = false;
      this.showSubtypeTable = false;
      window.alert(
        'The subtype analysis is based on cancer types which have subtype data, including BLCA, BRCA, COAD, GBM  HNSC, KIRC, LUAD, LUSC, READ, STAD and UCEC. Please select at least one of these cancer type to get the result of differential analysis.'
      );
    } else {
      this.showSubtypeTable = true;
      this.expressionApiService.getSubtypeTable(postTerm).subscribe(
        (res) => {
          this.subtypeTableLoading = false;
          this.subtypeTable = new MatTableDataSource(res);
          this.subtypeTable.paginator = this.paginatorSubtype;
          this.subtypeTable.sort = this.sortSubtype;
        },
        (err) => {
          this.showSubtypeTable = false;
          this.subtypeTableLoading = false;
        }
      );
      this.expressionApiService.getSubtypePlot(postTerm).subscribe(
        (res) => {
          this.subtypeImagePdfURL = this.expressionApiService.getResourcePlotURL(res.subtypeplotuuid, 'pdf');
          this.expressionApiService.getResourcePlotBlob(res.subtypeplotuuid, 'png').subscribe(
            (r) => {
              this.showSubtypeImage = true;
              this.subtypeImageLoading = false;
              this._createImageFromBlob(r, 'subtypeImage');
            },
            (e) => {
              this.showSubtypeImage = false;
              this.subtypeImageLoading = false;
            }
          );
        },
        (err) => {
          this.showSubtypeImage = false;
          this.subtypeImageLoading = false;
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
          case 'subtypeImage':
            this.subtypeImage = reader.result;
            break;
          case 'subtypeSingleGeneImage':
            this.subtypeSingleGeneImage = reader.result;
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
        return collectionlist.expr_subtype.collnames[collectionlist.expr_subtype.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }

  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.subtypeTable.filter = filterValue.trim().toLowerCase();

    if (this.subtypeTable.paginator) {
      this.subtypeTable.paginator.firstPage();
    }
  }

  public expandDetail(element: SubtypeTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.subtypeSingleGeneImageLoading = true;
      this.showSubtypeSingleGeneImage = false;
      if (this.expandedColumn === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [
            collectionlist.expr_subtype.collnames[collectionlist.expr_subtype.cancertypes.indexOf(this.expandedElement.cancertype)],
          ],
        };

        this.expressionApiService.getSubtypeSingleGenePlot(postTerm).subscribe(
          (res) => {
            this.subtypeSingleGenePdfURL = this.expressionApiService.getResourcePlotURL(res.subtypesinglegeneuuid, 'pdf');
            this.expressionApiService.getResourcePlotBlob(res.subtypesinglegeneuuid, 'png').subscribe(
              (r) => {
                this._createImageFromBlob(r, 'subtypeSingleGeneImage');
                this.subtypeSingleGeneImageLoading = false;
                this.showSubtypeSingleGeneImage = true;
              },
              (e) => {
                this.subtypeSingleGeneImageLoading = false;
                this.showSubtypeSingleGeneImage = false;
              }
            );
          },
          (err) => {
            this.subtypeSingleGeneImageLoading = false;
            this.showSubtypeSingleGeneImage = false;
          }
        );
      }
    } else {
      this.subtypeSingleGeneImageLoading = false;
      this.showSubtypeSingleGeneImage = false;
    }
  }

  public triggerDetail(element: SubtypeTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
  public exportExcel() {
    const workSheet = XLSX.utils.json_to_sheet(this.subtypeTable.data, { header: this.displayedColumnsSubtype });
    const workBook: XLSX.WorkBook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workBook, workSheet, 'SheetName');
    XLSX.writeFile(workBook, 'ExpressionAndSubtypeTable.xlsx');
  }
}
