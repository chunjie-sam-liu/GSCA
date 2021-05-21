import { AfterViewInit, Component, ElementRef, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { ImmGenesetDiffTableRecord } from 'src/app/shared/model/immunegenesetcnv';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { ImmuneApiService } from '../immune-api.service';
import { animate, state, style, transition, trigger } from '@angular/animations';
import * as XLSX from 'xlsx';

@Component({
  selector: 'app-immune-snv-geneset',
  templateUrl: './immune-snv-geneset.component.html',
  styleUrls: ['./immune-snv-geneset.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class ImmuneSnvGenesetComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;
  
  // immSnv cor table data source
  dataSourceImmGenesetSnvCorLoading = true;
  dataSourceImmGenesetSnvCor: MatTableDataSource<ImmGenesetDiffTableRecord>;
  showImmGenesetSnvCorTable = true;
  @ViewChild('paginatorImmSnvCor') paginatorImmSnvCor: MatPaginator;
  @ViewChild(MatSort) sortImmSnvCor: MatSort;
  displayedColumnsImmGenesetSnvCor = ['cancertype', 'celltype', 'p_value', 'fdr',"method_short"];
  displayedColumnsImmGenesetSnvCorHeader = ['Cancer type', 'Immune cell type', 'P value', 'FDR', "Method"];
  expandedElement: ImmGenesetDiffTableRecord;
  expandedColumn: string;

  // immSnv cor plot
  immGenesetSnvCorImageLoading = true;
  immGenesetSnvCorImage: any;
  showImmGenesetSnvCorImage = true;
  immGenesetSnvCorPdfURL: string;

  // single gene cor
  immGenesetSnvCorSingleGeneImage: any;
  immGenesetSnvCorSingleGeneImageLoading = true;
  showImmGenesetSnvCorSingleGeneImage = false;
  immGenesetSnvCorSingleGenePdfURL: string;

  dataSourceImmGenesetSnvCorUUID: string;

  constructor(private immuneApiService: ImmuneApiService) {}

  ngOnInit(): void {
  }
  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.dataSourceImmGenesetSnvCorLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceImmGenesetSnvCorLoading = false;
      this.showImmGenesetSnvCorTable = false;
      this.immGenesetSnvCorImageLoading = false;
      this.showImmGenesetSnvCorImage = false;
    } else {
      this.immuneApiService.getGeneSetSNVAnalysis(postTerm).subscribe(
        (res) => {
          this.dataSourceImmGenesetSnvCorUUID = res.uuidname;
          this.immuneApiService.getSnvImmGenesetCorPlot(res.uuidname).subscribe(
            (snvgenesetres) => {
              this.showImmGenesetSnvCorTable = true;
              this.immuneApiService
                .getResourceTable('preanalysised_snvgeneset_immu', snvgenesetres.snvimmunegenesetcortableuuid)
                .subscribe(
                  (r) => {
                    this.dataSourceImmGenesetSnvCorLoading = false;
                    this.dataSourceImmGenesetSnvCor = new MatTableDataSource(r);
                    this.dataSourceImmGenesetSnvCor.paginator = this.paginatorImmSnvCor;
                    this.dataSourceImmGenesetSnvCor.sort = this.sortImmSnvCor;
                  },
                  (e) => {
                    this.showImmGenesetSnvCorTable = false;
                  }
                );
              this.immGenesetSnvCorPdfURL = this.immuneApiService.getResourcePlotURL(snvgenesetres.snvimmunegenesetcorplotuuid, 'pdf');
              this.immuneApiService.getResourcePlotBlob(snvgenesetres.snvimmunegenesetcorplotuuid, 'png').subscribe(
                (r) => {
                  this.showImmGenesetSnvCorImage = true;
                  this.immGenesetSnvCorImageLoading = false;
                  this._createImageFromBlob(r, 'immGenesetSnvCorImage');
                },
                (e) => {
                  this.showImmGenesetSnvCorImage = false;
                }
              );
            },
            (e) => {
              this.showImmGenesetSnvCorImage = false;
              this.showImmGenesetSnvCorTable = false;
              this.dataSourceImmGenesetSnvCorLoading = false;
              this.immGenesetSnvCorImageLoading = false;
            }
          );
        },
        (err) => {
          this.showImmGenesetSnvCorImage = false;
          this.showImmGenesetSnvCorTable = false;
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
          case 'immGenesetSnvCorImage':
            this.immGenesetSnvCorImage = reader.result;
            break;
          case 'immGenesetSnvCorSingleGeneImage':
            this.immGenesetSnvCorSingleGeneImage = reader.result;
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
        return collectionlist.immune_cor_snv.collnames[collectionlist.immune_cor_snv.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }
  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceImmGenesetSnvCor.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceImmGenesetSnvCor.paginator) {
      this.dataSourceImmGenesetSnvCor.paginator.firstPage();
    }
  }

  public expandDetail(element: ImmGenesetDiffTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.immGenesetSnvCorSingleGeneImageLoading = true;
      this.showImmGenesetSnvCorSingleGeneImage = false;
      if (this.expandedColumn === 'cancertype') {
        this.immuneApiService
          .getImmSnvGenesetCorSingleGene(this.dataSourceImmGenesetSnvCorUUID, this.expandedElement.cancertype, this.expandedElement.celltype)
          .subscribe(
            (res) => {
              this.immGenesetSnvCorSingleGenePdfURL = this.immuneApiService.getResourcePlotURL(res.immgenesetsnvcorsinglegeneuuid, 'pdf');
              this.immuneApiService.getResourcePlotBlob(res.immgenesetsnvcorsinglegeneuuid, 'png').subscribe(
                (r) => {
                  this._createImageFromBlob(r, 'immGenesetSnvCorSingleGeneImage');
                  this.immGenesetSnvCorSingleGeneImageLoading = false;
                  this.showImmGenesetSnvCorSingleGeneImage = true;
                },
                (e) => {
                  this.showImmGenesetSnvCorSingleGeneImage = false;
                }
              );
            },
            (err) => {
              this.immGenesetSnvCorSingleGeneImageLoading = false;
              this.showImmGenesetSnvCorSingleGeneImage = false;
            }
          );
      }
    } else {
      this.immGenesetSnvCorSingleGeneImageLoading = false;
      this.showImmGenesetSnvCorSingleGeneImage = false;
    }
  }
  public triggerDetail(element: ImmGenesetDiffTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
  public exportExcel() {
    const workSheet = XLSX.utils.json_to_sheet(this.dataSourceImmGenesetSnvCor.data, { header: this.displayedColumnsImmGenesetSnvCor });
    const workBook: XLSX.WorkBook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workBook, workSheet, 'SheetName');
    XLSX.writeFile(workBook, 'ImmuneAndGenesetSnvTable.xlsx');
  }
}
