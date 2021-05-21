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
  dataSourceImmGenesetCnvCorLoading = true;
  dataSourceImmGenesetCnvCor: MatTableDataSource<ImmCorTableRecord>;
  showImmGenesetCnvCorTable = true;
  @ViewChild('paginatorImmCnvCor') paginatorImmCnvCor: MatPaginator;
  @ViewChild(MatSort) sortImmCnvCor: MatSort;
  displayedColumnsImmGenesetCnvCor = ['cancertype', 'symbol', 'cell_type', 'cor', 'fdr'];
  displayedColumnsImmGenesetCnvCorHeader = ['Cancer type', 'Gene symbol', 'Cell type', 'Correlation', 'FDR'];
  expandedElement: ImmCorTableRecord;
  expandedColumn: string;

  // immCnv cor plot
  immGenesetCnvCorImageLoading = true;
  immGenesetCnvCorImage: any;
  showImmGenesetCnvCorImage = true;
  immGenesetCnvCorPdfURL: string;

  // single gene cor
  immGenesetCnvCorSingleGeneImage: any;
  immGenesetCnvCorSingleGeneImageLoading = true;
  showImmGenesetCnvCorSingleGeneImage = false;
  immGenesetCnvCorSingleGenePdfURL: string;

  dataSourceImmGenesetCnvCorUUID: string;

  constructor(private immuneApiService: ImmuneApiService) {}

  ngOnInit(): void {}
  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.dataSourceImmGenesetCnvCorLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceImmGenesetCnvCorLoading = false;
      this.showImmGenesetCnvCorTable = false;
      this.immGenesetCnvCorImageLoading = false;
      this.showImmGenesetCnvCorImage = false;
    } else {
      this.immuneApiService.getGeneSetCNVAnalysis(postTerm).subscribe(
        (res) => {
          this.dataSourceImmGenesetCnvCorUUID = res.uuidname;
          this.immuneApiService.getCnvImmGenesetCorPlot(res.uuidname).subscribe(
            (cnvgenesetres) => {
              this.showImmGenesetCnvCorTable = true;
              this.immuneApiService
                .getResourceTable('preanalysised_cnvgeneset_immune', cnvgenesetres.cnvimmunegenesetcortableuuid)
                .subscribe(
                  (r) => {
                    this.dataSourceImmGenesetCnvCorLoading = false;
                    this.dataSourceImmGenesetCnvCor = new MatTableDataSource(r);
                    this.dataSourceImmGenesetCnvCor.paginator = this.paginatorImmCnvCor;
                    this.dataSourceImmGenesetCnvCor.sort = this.sortImmCnvCor;
                  },
                  (e) => {
                    this.showImmGenesetCnvCorTable = false;
                  }
                );
              this.immGenesetCnvCorPdfURL = this.immuneApiService.getResourcePlotURL(cnvgenesetres.cnvimmunegenesetcorplotuuid, 'pdf');
              this.immuneApiService.getResourcePlotBlob(cnvgenesetres.cnvimmunegenesetcorplotuuid, 'png').subscribe(
                (r) => {
                  this.showImmGenesetCnvCorImage = true;
                  this.immGenesetCnvCorImageLoading = false;
                  this._createImageFromBlob(r, 'immGenesetCnvCorImage');
                },
                (e) => {
                  this.showImmGenesetCnvCorImage = false;
                }
              );
            },
            (e) => {
              this.showImmGenesetCnvCorImage = false;
              this.showImmGenesetCnvCorTable = false;
              this.dataSourceImmGenesetCnvCorLoading = false;
              this.immGenesetCnvCorImageLoading = false;
            }
          );
        },
        (err) => {
          this.showImmGenesetCnvCorImage = false;
          this.showImmGenesetCnvCorTable = false;
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
          case 'immGenesetCnvCorImage':
            this.immGenesetCnvCorImage = reader.result;
            break;
          case 'immGenesetCnvCorSingleGeneImage':
            this.immGenesetCnvCorSingleGeneImage = reader.result;
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
    this.dataSourceImmGenesetCnvCor.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceImmGenesetCnvCor.paginator) {
      this.dataSourceImmGenesetCnvCor.paginator.firstPage();
    }
  }

  public expandDetail(element: ImmCorTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.immGenesetCnvCorSingleGeneImageLoading = true;
      this.showImmGenesetCnvCorSingleGeneImage = false;
      if (this.expandedColumn === 'cancertype') {
        this.immuneApiService
          .getImmCnvGenesetCorSingleGene(this.dataSourceImmGenesetCnvCorUUID, this.expandedElement.cancertype, this.expandedElement.cell_type)
          .subscribe(
            (res) => {
              this.immGenesetCnvCorSingleGenePdfURL = this.immuneApiService.getResourcePlotURL(res.immgenesetcnvcorsinglegeneuuid, 'pdf');
              this.immuneApiService.getResourcePlotBlob(res.immgenesetcnvcorsinglegeneuuid, 'png').subscribe(
                (r) => {
                  this._createImageFromBlob(r, 'immGenesetCnvCorSingleGeneImage');
                  this.immGenesetCnvCorSingleGeneImageLoading = false;
                  this.showImmGenesetCnvCorSingleGeneImage = true;
                },
                (e) => {
                  this.showImmGenesetCnvCorSingleGeneImage = false;
                }
              );
            },
            (err) => {
              this.immGenesetCnvCorSingleGeneImageLoading = false;
              this.showImmGenesetCnvCorSingleGeneImage = false;
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
            this.immGenesetCnvCorPdfURL = this.immuneApiService.getResourcePlotURL(res.immcnvcorplotuuid, 'pdf');
            this.immuneApiService.getResourcePlotBlob(res.immcnvcorplotuuid, 'png').subscribe(
              (r) => {
                this.showImmGenesetCnvCorImage = true;
                this.immGenesetCnvCorImageLoading = false;
                this.immGenesetCnvCorSingleGeneImageLoading = false;
                this.showImmGenesetCnvCorSingleGeneImage = false;
                this._createImageFromBlob(r, 'immCnvCorImage');
              },
              (e) => {
                this.showImmGenesetCnvCorSingleGeneImage = false;
                this.immGenesetCnvCorSingleGeneImageLoading = false;
              }
            );
          },
          (err) => {
            this.immGenesetCnvCorImageLoading = false;
            this.showImmGenesetCnvCorImage = false;
            this.immGenesetCnvCorSingleGeneImageLoading = false;
            this.showImmGenesetCnvCorSingleGeneImage = false;
          }
        );
      }
    } else {
      this.immGenesetCnvCorSingleGeneImageLoading = false;
      this.showImmGenesetCnvCorSingleGeneImage = false;
    }
  }
  public triggerDetail(element: ImmCorTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
}
