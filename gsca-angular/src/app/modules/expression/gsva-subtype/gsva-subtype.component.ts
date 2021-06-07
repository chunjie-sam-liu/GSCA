import { Component, OnInit, OnChanges, AfterViewInit, SimpleChanges, Input, ViewChild } from '@angular/core';
import { ExpressionApiService } from './../expression-api.service';
import { ExprSearch } from './../../../shared/model/exprsearch';
import collectionList from 'src/app/shared/constants/collectionlist';
import { MatTableDataSource } from '@angular/material/table';
import { GSVASubtypeTableRecord } from 'src/app/shared/model/gsvasubtypetablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import * as XLSX from 'xlsx';
@Component({
  selector: 'app-gsva-subtype',
  templateUrl: './gsva-subtype.component.html',
  styleUrls: ['./gsva-subtype.component.css'],
})
export class GsvaSubtypeComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // GSVA subtype table
  dataSourceGSVASubtypeLoading = true;
  dataSourceGSVASubtype: MatTableDataSource<GSVASubtypeTableRecord>;
  showGSVASubtypeTable = true;
  @ViewChild('paginatorGSVASubtype') paginatorGSVASubtype: MatPaginator;
  @ViewChild(MatSort) sortGSVASubtype: MatSort;
  displayedColumnsGSVASubtype = ['cancertype', 'diff_p', 'Subtype1', 'Subtype2', 'Subtype3', 'Subtype4', 'Subtype5', 'Subtype6'];
  displayedColumnsGSVASubtypeHeader = [
    'Cancer type',
    'P value',
    'Subtype1 (mean/n)',
    'Subtype2 (mean/n)',
    'Subtype3 (mean/n)',
    'Subtype4 (mean/n)',
    'Subtype5 (mean/n)',
    'Subtype6 (mean/n)',
  ];
  expandedElement: GSVASubtypeTableRecord;
  expandedColumn: string;

  // GSVA subtype image
  GSVASubtypeImage: any;
  GSVASubtypePdfURL: string;
  GSVASubtypeImageLoading = true;
  showGSVASubtypeImage = true;

  // GSVA subtype image
  GSVASubtypeTrendImage: any;
  GSVASubtypeTrendPdfURL: string;
  GSVASubtypeTrendImageLoading = true;
  showGSVASubtypeTrendImage = true;

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    this.dataSourceGSVASubtypeLoading = true;
    this.GSVASubtypeImageLoading = true;
    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceGSVASubtypeLoading = false;
      this.GSVASubtypeImageLoading = false;
      this.showGSVASubtypeTable = false;
      this.showGSVASubtypeImage = false;
      window.alert(
        'The subtype analysis is based on cancer types which have subtype data, including BLCA, BRCA, COAD, GBM  HNSC, KIRC, LUAD, LUSC, READ, STAD and UCEC. Please select at least one of these cancer type to get the result of differential analysis.'
      );
    } else {
      this.expressionApiService.getGSVAAnalysis(postTerm).subscribe(
        (res) => {
          this.expressionApiService.getExprSubtypeGSVAPlot(res.uuidname).subscribe(
            (exprgsvauuids) => {
              this.showGSVASubtypeTable = true;
              this.expressionApiService.getResourceTable('preanalysised_gsva_subtype', exprgsvauuids.exprsubtypegsvatableuuid).subscribe(
                (r) => {
                  this.dataSourceGSVASubtypeLoading = false;
                  this.dataSourceGSVASubtype = new MatTableDataSource(r);
                  this.dataSourceGSVASubtype.paginator = this.paginatorGSVASubtype;
                  this.dataSourceGSVASubtype.sort = this.sortGSVASubtype;
                },
                (e) => {
                  this.showGSVASubtypeTable = false;
                }
              );
              this.GSVASubtypePdfURL = this.expressionApiService.getResourcePlotURL(exprgsvauuids.exprsubtypegsvaplotuuid, 'pdf');
              this.expressionApiService.getResourcePlotBlob(exprgsvauuids.exprsubtypegsvaplotuuid, 'png').subscribe(
                (r) => {
                  this.showGSVASubtypeImage = true;
                  this.GSVASubtypeImageLoading = false;
                  this._createImageFromBlob(r, 'GSVASubtypeImage');
                },
                (e) => {
                  this.showGSVASubtypeImage = false;
                }
              );
            },
            (e) => {
              this.dataSourceGSVASubtypeLoading = false;
              this.GSVASubtypeImageLoading = false;
              this.showGSVASubtypeTable = false;
              this.showGSVASubtypeImage = false;
            }
          );
        },
        (err) => {
          this.showGSVASubtypeTable = false;
          this.showGSVASubtypeImage = false;
          this.showGSVASubtypeTrendImage = false;
        }
      );
    }
  }

  ngAfterViewInit(): void {}

  private _validCollection(st: ExprSearch): any {
    st.validColl = st.cancerTypeSelected
      .map((val) => {
        return collectionList.expr_subtype.collnames[collectionList.expr_subtype.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }

  private _createImageFromBlob(res: Blob, present: string) {
    const reader = new FileReader();
    reader.addEventListener(
      'load',
      () => {
        switch (present) {
          case 'GSVASubtypeImage':
            this.GSVASubtypeImage = reader.result;
            break;
          case 'GSVASubtypeTrendImage':
            this.GSVASubtypeTrendImage = reader.result;
            break;
        }
      },
      false
    );
    if (res) {
      reader.readAsDataURL(res);
    }
  }

  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceGSVASubtype.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceGSVASubtype.paginator) {
      this.dataSourceGSVASubtype.paginator.firstPage();
    }
  }
  public exportExcel() {
    const workSheet = XLSX.utils.json_to_sheet(this.dataSourceGSVASubtype.data, { header: this.displayedColumnsGSVASubtype });
    const workBook: XLSX.WorkBook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workBook, workSheet, 'SheetName');
    XLSX.writeFile(workBook, 'GsvaSubtypeTable.xlsx');
  }
}
