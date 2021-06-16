import { Component, OnInit, OnChanges, AfterViewInit, SimpleChanges, Input, ViewChild } from '@angular/core';
import { ImmuneApiService } from './../immune-api.service';
import { ExprSearch } from './../../../shared/model/exprsearch';
import collectionList from 'src/app/shared/constants/collectionlist';
import { MatTableDataSource } from '@angular/material/table';
import { GSVAImmuTableRecord } from 'src/app/shared/model/gsvaImmutablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { animate, state, style, transition, trigger } from '@angular/animations';
import * as XLSX from 'xlsx';

@Component({
  selector: 'app-immune-gsva',
  templateUrl: './immune-gsva.component.html',
  styleUrls: ['./immune-gsva.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class ImmuneGsvaComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // GSVA Immu table
  dataSourceGSVAImmuLoading = true;
  dataSourceGSVAImmu: MatTableDataSource<GSVAImmuTableRecord>;
  showGSVAImmuTable = true;
  @ViewChild('paginatorGSVAImmu') paginatorGSVAImmu: MatPaginator;
  @ViewChild(MatSort) sortGSVAImmu: MatSort;
  displayedColumnsGSVAImmu = ['cancertype', 'celltype', 'estimate', 'p_value', 'fdr'];
  displayedColumnsGSVAImmuHeader = ['Cancer type', 'Cell type', 'Spearman cor.', 'P value', 'FDR'];
  expandedElement: GSVAImmuTableRecord;
  expandedColumn: string;

  // GSVA Immu image
  GSVAImmuImage: any;
  GSVAImmuPdfURL: string;
  GSVAImmuImageLoading = true;
  showGSVAImmuImage = true;

  // GSVA Immu single cancer image
  gsvaImmuResourceUUID: string;
  GSVAImmuSingleCellImage: any;
  GSVAImmuSingleCellPdfURL: string;
  GSVAImmuSingleCellImageLoading = true;
  showGSVAImmuSingleCellImage = true;

  constructor(private immuneApiService: ImmuneApiService) {}

  ngOnInit(): void {}
  ngOnChanges(changes: SimpleChanges): void {
    this.dataSourceGSVAImmuLoading = true;
    this.GSVAImmuImageLoading = true;
    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceGSVAImmuLoading = false;
      this.GSVAImmuImageLoading = false;
      this.showGSVAImmuTable = false;
      this.showGSVAImmuImage = false;
    } else {
      this.immuneApiService.getGSVAAnalysis(postTerm).subscribe(
        (res) => {
          this.gsvaImmuResourceUUID = res.uuidname;
          this.immuneApiService.getImmuGSVAPlot(res.uuidname).subscribe(
            (immugsvauuids) => {
              this.showGSVAImmuTable = true;
              this.immuneApiService.getResourceTable('preanalysised_gsva_immu', immugsvauuids.immugsvatableuuid).subscribe(
                (r) => {
                  this.dataSourceGSVAImmuLoading = false;
                  this.dataSourceGSVAImmu = new MatTableDataSource(r);
                  this.dataSourceGSVAImmu.paginator = this.paginatorGSVAImmu;
                  this.dataSourceGSVAImmu.sort = this.sortGSVAImmu;
                },
                (e) => {
                  this.showGSVAImmuTable = false;
                }
              );
              this.GSVAImmuPdfURL = this.immuneApiService.getResourcePlotURL(immugsvauuids.immugsvaplotuuid, 'pdf');
              this.immuneApiService.getResourcePlotBlob(immugsvauuids.immugsvaplotuuid, 'png').subscribe(
                (r) => {
                  this.showGSVAImmuImage = true;
                  this.GSVAImmuImageLoading = false;
                  this._createImageFromBlob(r, 'GSVAImmuImage');
                },
                (e) => {
                  this.showGSVAImmuImage = false;
                }
              );
            },
            (e) => {
              this.dataSourceGSVAImmuLoading = false;
              this.GSVAImmuImageLoading = false;
              this.showGSVAImmuTable = false;
              this.showGSVAImmuImage = false;
            }
          );
        },
        (err) => {
          this.showGSVAImmuTable = false;
          this.showGSVAImmuImage = false;
        }
      );
    }
  }

  ngAfterViewInit(): void {}

  private _validCollection(st: ExprSearch): any {
    st.validColl = st.cancerTypeSelected
      .map((val) => {
        return collectionList.immune_cor_expr.collnames[collectionList.immune_cor_expr.cancertypes.indexOf(val)];
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
          case 'GSVAImmuImage':
            this.GSVAImmuImage = reader.result;
            break;
          case 'GSVAImmuSingleCellImage':
            this.GSVAImmuSingleCellImage = reader.result;
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
    this.dataSourceGSVAImmu.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceGSVAImmu.paginator) {
      this.dataSourceGSVAImmu.paginator.firstPage();
    }
  }

  public expandDetail(element: GSVAImmuTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.GSVAImmuSingleCellImageLoading = true;
      this.showGSVAImmuSingleCellImage = false;
      if (this.expandedColumn === 'celltype') {
        this.immuneApiService
          .getGSVAImmuSingleCellImage(this.gsvaImmuResourceUUID, this.expandedElement.cancertype, this.expandedElement.celltype)
          .subscribe(
            (res) => {
              this.GSVAImmuSingleCellPdfURL = this.immuneApiService.getResourcePlotURL(res.gsvaimmusinglecelluuid, 'pdf');
              this.immuneApiService.getResourcePlotBlob(res.gsvaimmusinglecelluuid, 'png').subscribe(
                (r) => {
                  this.showGSVAImmuSingleCellImage = true;
                  this.GSVAImmuSingleCellImageLoading = false;
                  this._createImageFromBlob(r, 'GSVAImmuSingleCellImage');
                },
                (e) => {
                  this.showGSVAImmuSingleCellImage = false;
                  this.GSVAImmuSingleCellImageLoading = false;
                }
              );
            },
            (err) => {
              this.showGSVAImmuSingleCellImage = false;
              this.GSVAImmuSingleCellImageLoading = false;
            }
          );
      }
    } else {
      this.GSVAImmuSingleCellImageLoading = false;
      this.showGSVAImmuSingleCellImage = false;
    }
  }

  public triggerDetail(element: GSVAImmuTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
  public exportExcel() {
    const workSheet = XLSX.utils.json_to_sheet(this.dataSourceGSVAImmu.data, { header: this.displayedColumnsGSVAImmu });
    const workBook: XLSX.WorkBook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workBook, workSheet, 'SheetName');
    XLSX.writeFile(workBook, 'GsvaImmuTable.xlsx');
  }
}
