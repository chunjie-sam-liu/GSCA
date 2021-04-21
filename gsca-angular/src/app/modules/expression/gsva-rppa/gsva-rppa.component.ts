import { Component, OnInit, OnChanges, AfterViewInit, SimpleChanges, Input, ViewChild } from '@angular/core';
import { ExpressionApiService } from './../expression-api.service';
import { ExprSearch } from './../../../shared/model/exprsearch';
import collectionList from 'src/app/shared/constants/collectionlist';
import { MatTableDataSource } from '@angular/material/table';
import { GSVARPPATableRecord } from 'src/app/shared/model/gsvaRPPAtablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { animate, state, style, transition, trigger } from '@angular/animations';
import * as XLSX from 'xlsx';

@Component({
  selector: 'app-gsva-rppa',
  templateUrl: './gsva-rppa.component.html',
  styleUrls: ['./gsva-rppa.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class GsvaRppaComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // GSVA RPPA table
  dataSourceGSVARPPALoading = true;
  dataSourceGSVARPPA: MatTableDataSource<GSVARPPATableRecord>;
  showGSVARPPATable = true;
  @ViewChild('paginatorGSVARPPA') paginatorGSVARPPA: MatPaginator;
  @ViewChild(MatSort) sortGSVARPPA: MatSort;
  displayedColumnsGSVARPPA = ['cancertype', 'pathway', 'pval', 'fdr', 'class'];
  displayedColumnsGSVARPPAHeader = ['Cancer type', 'Pathway', 'P value', 'FDR', 'Potential effects of gene mRNA on pathway activity'];
  expandedElement: GSVARPPATableRecord;
  expandedColumn: string;

  // GSVA RPPA image
  GSVARPPAImage: any;
  GSVARPPAPdfURL: string;
  GSVARPPAImageLoading = true;
  showGSVARPPAImage = true;

  // GSVA RPPA single cancer image
  gsvaRPPAResourceUUID: string;
  GSVARPPASingleCancerImage: any;
  GSVARPPASingleCancerPdfURL: string;
  GSVARPPASingleCancerImageLoading = true;
  showGSVARPPASingleCancerImage = true;

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    this.dataSourceGSVARPPALoading = true;
    this.GSVARPPAImageLoading = true;
    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceGSVARPPALoading = false;
      this.GSVARPPAImageLoading = false;
      this.showGSVARPPATable = false;
      this.showGSVARPPAImage = false;
    } else {
      this.expressionApiService.getGSVAAnalysis(postTerm).subscribe(
        (res) => {
          this.gsvaRPPAResourceUUID = res.uuidname;
          this.expressionApiService.getRPPAGSVAPlot(res.uuidname).subscribe(
            (exprgsvauuids) => {
              this.showGSVARPPATable = true;
              this.expressionApiService.getResourceTable('preanalysised_gsva_RPPA', exprgsvauuids.rppagsvaplotuuid).subscribe(
                (r) => {
                  this.dataSourceGSVARPPALoading = false;
                  this.dataSourceGSVARPPA = new MatTableDataSource(r);
                  this.dataSourceGSVARPPA.paginator = this.paginatorGSVARPPA;
                  this.dataSourceGSVARPPA.sort = this.sortGSVARPPA;
                },
                (e) => {
                  this.showGSVARPPATable = false;
                }
              );
              this.GSVARPPAPdfURL = this.expressionApiService.getResourcePlotURL(exprgsvauuids.rppagsvaplotuuid, 'pdf');
              this.expressionApiService.getResourcePlotBlob(exprgsvauuids.rppagsvaplotuuid, 'png').subscribe(
                (r) => {
                  this.showGSVARPPAImage = true;
                  this.GSVARPPAImageLoading = false;
                  this._createImageFromBlob(r, 'GSVARPPAImage');
                },
                (e) => {
                  this.showGSVARPPAImage = false;
                }
              );
            },
            (e) => {
              this.dataSourceGSVARPPALoading = false;
              this.GSVARPPAImageLoading = false;
              this.showGSVARPPATable = false;
              this.showGSVARPPAImage = false;
            }
          );
        },
        (err) => {
          this.showGSVARPPATable = false;
          this.showGSVARPPAImage = false;
        }
      );
    }
  }

  ngAfterViewInit(): void {}

  private _validCollection(st: ExprSearch): any {
    st.validColl = st.cancerTypeSelected
      .map((val) => {
        return collectionList.rppa_diff.collnames[collectionList.rppa_diff.cancertypes.indexOf(val)];
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
          case 'GSVARPPAImage':
            this.GSVARPPAImage = reader.result;
            break;
          case 'GSVARPPASingleCancerImage':
            this.GSVARPPASingleCancerImage = reader.result;
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
    this.dataSourceGSVARPPA.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceGSVARPPA.paginator) {
      this.dataSourceGSVARPPA.paginator.firstPage();
    }
  }

  public expandDetail(element: GSVARPPATableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.GSVARPPASingleCancerImageLoading = true;
      this.showGSVARPPASingleCancerImage = false;
      if (this.expandedColumn === 'cancertype') {
        this.expressionApiService
          .getGSVARPPASingleCancerImage(this.gsvaRPPAResourceUUID, this.expandedElement.cancertype, this.expandedElement.pathway)
          .subscribe(
            (res) => {
              this.GSVARPPASingleCancerPdfURL = this.expressionApiService.getResourcePlotURL(res.gsvaRPPAsinglecanceruuid, 'pdf');
              this.expressionApiService.getResourcePlotBlob(res.gsvaRPPAsinglecanceruuid, 'png').subscribe(
                (r) => {
                  this.showGSVARPPASingleCancerImage = true;
                  this.GSVARPPASingleCancerImageLoading = false;
                  this._createImageFromBlob(r, 'GSVARPPASingleCancerImage');
                },
                (e) => {
                  this.showGSVARPPASingleCancerImage = false;
                  this.GSVARPPASingleCancerImageLoading = false;
                }
              );
            },
            (err) => {
              this.showGSVARPPASingleCancerImage = false;
              this.GSVARPPASingleCancerImageLoading = false;
            }
          );
      }
    } else {
      this.GSVARPPASingleCancerImageLoading = false;
      this.showGSVARPPASingleCancerImage = false;
    }
  }

  public triggerDetail(element: GSVARPPATableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
  public exportExcel() {
    const workSheet = XLSX.utils.json_to_sheet(this.dataSourceGSVARPPA.data, { header: this.displayedColumnsGSVARPPA });
    const workBook: XLSX.WorkBook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workBook, workSheet, 'SheetName');
    XLSX.writeFile(workBook, 'GsvaRPPATable.xlsx');
  }
}
