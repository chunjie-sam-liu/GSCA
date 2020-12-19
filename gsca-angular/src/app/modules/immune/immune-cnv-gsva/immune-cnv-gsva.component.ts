import { AfterViewInit, Component, ElementRef, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { ImmCorTableRecord } from 'src/app/shared/model/immunecortablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { ImmuneApiService } from '../immune-api.service';
import { animate, state, style, transition, trigger } from '@angular/animations';

@Component({
  selector: 'app-immune-cnv-gsva',
  templateUrl: './immune-cnv-gsva.component.html',
  styleUrls: ['./immune-cnv-gsva.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class ImmuneCnvGsvaComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // immCnv cor table data source
  dataSourceImmCnvCorLoading = true;
  dataSourceImmCnvCor: MatTableDataSource<ImmCorTableRecord>;
  showImmCnvCorTable = true;
  @ViewChild('paginatorImmCnvCor') paginatorImmCnvCor: MatPaginator;
  @ViewChild(MatSort) sortImmCnvCor: MatSort;
  displayedColumnsImmCnvCor = ['cancertype', 'symbol', 'cell_type', 'cor', 'fdr'];
  displayedColumnsImmCnvCorHeader = ['Cancer type', 'Gene symbol', 'Cell type', 'Correlation', 'FDR'];
  expandedElement: ImmCorTableRecord;
  expandedColumn: string;

  // immCnv cor plot
  immCnvCorImageLoading = true;
  immCnvCorImage: any;
  showImmCnvCorImage = true;
  immCnvCorPdfURL: string;

  // single gene cor
  immCnvCorSingleGeneImage: any;
  immCnvCorSingleGeneImageLoading = true;
  showImmCnvCorSingleGeneImage = false;
  immCnvCorSingleGenePdfURL: string;

  dataSourceImmCnvCorUUID: any;

  constructor(private immuneApiService: ImmuneApiService) {}

  ngOnInit(): void {}
  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.dataSourceImmCnvCorLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceImmCnvCorLoading = false;
      this.showImmCnvCorTable = false;
      this.immCnvCorImageLoading = false;
      this.showImmCnvCorImage = false;
    } else {
      this.immuneApiService.getGeneSetCNVAnalysis(postTerm).subscribe(
        (res) => {
          this.dataSourceImmCnvCorUUID = res.uuidname;
          this.immuneApiService.getCnvImmGenesetCorPlot(res.uuidname).subscribe(
            (cnvgenesetres) => {
              this.showImmCnvCorTable = true;
              this.immuneApiService
                .getResourceTable('preanalysised_cnvgeneset_immune', cnvgenesetres.cnvimmunegenesetcortableuuid)
                .subscribe(
                  (r) => {
                    this.dataSourceImmCnvCorLoading = false;
                    this.dataSourceImmCnvCor = new MatTableDataSource(r);
                    this.dataSourceImmCnvCor.paginator = this.paginatorImmCnvCor;
                    this.dataSourceImmCnvCor.sort = this.sortImmCnvCor;
                  },
                  (e) => {
                    this.showImmCnvCorTable = false;
                  }
                );
              this.immCnvCorPdfURL = this.immuneApiService.getResourcePlotURL(cnvgenesetres.cnvimmunegenesetcorplotuuid, 'pdf');
              this.immuneApiService.getResourcePlotBlob(cnvgenesetres.cnvimmunegenesetcorplotuuid, 'png').subscribe(
                (r) => {
                  this.showImmCnvCorImage = true;
                  this.immCnvCorImageLoading = false;
                  this._createImageFromBlob(r, 'immCnvCorImage');
                },
                (e) => {
                  this.showImmCnvCorImage = false;
                }
              );
            },
            (e) => {
              this.showImmCnvCorImage = false;
              this.showImmCnvCorTable = false;
              this.dataSourceImmCnvCorLoading = false;
              this.immCnvCorImageLoading = false;
            }
          );
        },
        (err) => {
          this.showImmCnvCorImage = false;
          this.showImmCnvCorTable = false;
        }
      );
      this.showImmCnvCorTable = true;
      this.immuneApiService.getImmCnvCorTable(postTerm).subscribe(
        (res) => {
          this.dataSourceImmCnvCorLoading = false;
          this.dataSourceImmCnvCor = new MatTableDataSource(res);
          this.dataSourceImmCnvCor.paginator = this.paginatorImmCnvCor;
          this.dataSourceImmCnvCor.sort = this.sortImmCnvCor;
        },
        (err) => {
          this.dataSourceImmCnvCorLoading = false;
          this.showImmCnvCorTable = false;
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
          case 'immCnvCorImage':
            this.immCnvCorImage = reader.result;
            break;
          case 'immCnvCorSingleGeneImage':
            this.immCnvCorSingleGeneImage = reader.result;
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
        return collectionlist.immune_cor_cnv.collnames[collectionlist.immune_cor_cnv.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }
  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceImmCnvCor.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceImmCnvCor.paginator) {
      this.dataSourceImmCnvCor.paginator.firstPage();
    }
  }

  public expandDetail(element: ImmCorTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.immCnvCorSingleGeneImageLoading = true;
      this.showImmCnvCorSingleGeneImage = false;
      if (this.expandedColumn === 'cancertype') {
        this.immuneApiService
          .getImmCnvGenesetCorSingleGene(this.dataSourceImmCnvCorUUID, this.expandedElement.cancertype, this.expandedElement.cell_type)
          .subscribe(
            (res) => {
              this.immCnvCorSingleGenePdfURL = this.immuneApiService.getResourcePlotURL(res.immcnvcorsinglegeneuuid, 'pdf');
              this.immuneApiService.getResourcePlotBlob(res.immcnvcorsinglegeneuuid, 'png').subscribe(
                (r) => {
                  this._createImageFromBlob(r, 'immCnvCorSingleGeneImage');
                  this.immCnvCorSingleGeneImageLoading = false;
                  this.showImmCnvCorSingleGeneImage = true;
                },
                (e) => {
                  this.showImmCnvCorSingleGeneImage = false;
                }
              );
            },
            (err) => {
              this.immCnvCorSingleGeneImageLoading = false;
              this.showImmCnvCorSingleGeneImage = false;
            }
          );
      }
      if (this.expandedColumn === 'cancertype') {
        const postTerm = {
          validSymbol: this.searchTerm.validSymbol,
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [
            collectionlist.immune_cor_cnv.collnames[collectionlist.immune_cor_cnv.cancertypes.indexOf(this.expandedElement.cancertype)],
          ],
        };
        this.immuneApiService.getImmCnvCorPlot(postTerm).subscribe(
          (res) => {
            this.immCnvCorPdfURL = this.immuneApiService.getResourcePlotURL(res.immcnvcorplotuuid, 'pdf');
            this.immuneApiService.getResourcePlotBlob(res.immcnvcorplotuuid, 'png').subscribe(
              (r) => {
                this.showImmCnvCorImage = true;
                this.immCnvCorImageLoading = false;
                this.immCnvCorSingleGeneImageLoading = false;
                this.showImmCnvCorSingleGeneImage = false;
                this._createImageFromBlob(r, 'immCnvCorImage');
              },
              (e) => {
                this.showImmCnvCorSingleGeneImage = false;
                this.immCnvCorSingleGeneImageLoading = false;
              }
            );
          },
          (err) => {
            this.immCnvCorImageLoading = false;
            this.showImmCnvCorImage = false;
            this.immCnvCorSingleGeneImageLoading = false;
            this.showImmCnvCorSingleGeneImage = false;
          }
        );
      }
    } else {
      this.immCnvCorSingleGeneImageLoading = false;
      this.showImmCnvCorSingleGeneImage = false;
    }
  }
  public triggerDetail(element: ImmCorTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
}
