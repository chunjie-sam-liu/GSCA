import { Component, OnInit, OnChanges, AfterViewInit, SimpleChanges, Input, ViewChild } from '@angular/core';
import { ExpressionApiService } from './../expression-api.service';
import { ExprSearch } from './../../../shared/model/exprsearch';
import collectionList from 'src/app/shared/constants/collectionlist';
import { MatTableDataSource } from '@angular/material/table';
import { SampleGSVATableRecord } from 'src/app/shared/model/samplegsvatablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import * as XLSX from 'xlsx';

@Component({
  selector: 'app-gsvascore',
  templateUrl: './gsvascore.component.html',
  styleUrls: ['./gsvascore.component.css'],
})
export class GsvascoreComponent implements OnInit {
  @Input() searchTerm: ExprSearch;

  // GSVA score table
  dataSourceGSVALoading = true;
  dataSourceGSVA: MatTableDataSource<SampleGSVATableRecord>;
  showGSVATable = true;
  @ViewChild('paginatorGSVA') paginatorGSVA: MatPaginator;
  @ViewChild(MatSort) sortGSVA: MatSort;
  displayedColumnsGSVA = ['cancertype', 'barcode', 'type', 'gsva'];
  displayedColumnsGSVAHeader = ['Cancer type', 'Sample barcode', 'Sample type', 'GSVA score'];

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    this.dataSourceGSVALoading = true;
    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceGSVALoading = false;
      this.showGSVATable = false;
    } else {
      this.expressionApiService.getGSVAAnalysis(postTerm).subscribe(
        (res) => {
          this.expressionApiService.getGSVATableTransform(res.uuidname).subscribe(
            (gsvatableuuids) => {
              this.showGSVATable = true;
              this.expressionApiService.getResourceTable('preanalysised_gsva_transform', gsvatableuuids.transformgsvatableuuid).subscribe(
                (r) => {
                  this.dataSourceGSVALoading = false;
                  this.dataSourceGSVA = new MatTableDataSource(r);
                  this.dataSourceGSVA.paginator = this.paginatorGSVA;
                  this.dataSourceGSVA.sort = this.sortGSVA;
                },
                (e) => {
                  this.showGSVATable = false;
                  this.dataSourceGSVALoading = false;
                }
              );
            },
            (e) => {
              this.showGSVATable = false;
              this.dataSourceGSVALoading = false;
            }
          );
        },
        (err) => {
          this.showGSVATable = false;
          this.dataSourceGSVALoading = false;
        }
      );
    }
  }

  ngAfterViewInit(): void {}

  private _validCollection(st: ExprSearch): any {
    st.validColl = st.cancerTypeSelected
      .map((val) => {
        return collectionList.deg.collnames[collectionList.deg.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }

  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceGSVA.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceGSVA.paginator) {
      this.dataSourceGSVA.paginator.firstPage();
    }
  }
  public exportExcel() {
    const workSheet = XLSX.utils.json_to_sheet(this.dataSourceGSVA.data, { header: this.displayedColumnsGSVA });
    const workBook: XLSX.WorkBook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workBook, workSheet, 'SheetName');
    XLSX.writeFile(workBook, 'DifferentialGSVATable.xlsx');
  }
}
