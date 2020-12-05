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
  selector: 'app-immune-expr',
  templateUrl: './immune-expr.component.html',
  styleUrls: ['./immune-expr.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class ImmuneExprComponent implements  OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // immExpr cor table data source
  dataSourceImmExprCorLoading = true;
  dataSourceImmExprCor: MatTableDataSource<ImmCorTableRecord>;
  showImmExprCorTable = true;
  @ViewChild('paginatorImmExprCor') paginatorImmExprCor: MatPaginator;
  @ViewChild(MatSort) sortImmExprCor: MatSort;
  displayedColumnsImmExprCor = ['cancertype', 'symbol',  'cell_type','cor', 'fdr'];
  displayedColumnsImmExprCorHeader = [
    'Cancer type',
    'Gene symbol',
    "Cell type",
    'Correlation',
    'FDR',
  ];
  expandedElement: ImmCorTableRecord;
  expandedColumn: string;

  // immExpr cor plot
  immExprCorImageLoading = true;
  immExprCorImage: any;
  showImmExprCorImage = true;

  // single gene cor
  immExprCorSingleGeneImage: any;
  immExprCorSingleGeneImageLoading = true;
  showImmExprCorSingleGeneImage = false;

  constructor(private mutationApiService: ImmuneApiService) { }

  ngOnInit(): void {
  }
  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.dataSourceImmExprCorLoading = true;
    this.immExprCorImageLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceImmExprCorLoading = false;
      this.showImmExprCorTable = false;
    } else {
      this.showImmExprCorTable = true;
      this.mutationApiService.getImmExprCorTable(postTerm).subscribe(
        (res) => {
          this.dataSourceImmExprCorLoading = false;
          this.dataSourceImmExprCor = new MatTableDataSource(res);
          this.dataSourceImmExprCor.paginator = this.paginatorImmExprCor;
          this.dataSourceImmExprCor.sort = this.sortImmExprCor;
        },
        (err) => {
          this.dataSourceImmExprCorLoading = false;
          this.showImmExprCorTable = false;
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
          case 'immExprCorImage':
            this.immExprCorImage = reader.result;
            break;
          case 'immExprCorSingleGeneImage':
            this.immExprCorSingleGeneImage = reader.result;
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
        return collectionlist.immune_cor_expr.collnames[collectionlist.immune_cor_expr.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }
  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceImmExprCor.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceImmExprCor.paginator) {
      this.dataSourceImmExprCor.paginator.firstPage();
    }
  }

  public expandDetail(element: ImmCorTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.immExprCorSingleGeneImageLoading = true;
      this.showImmExprCorSingleGeneImage = false;
      this.immExprCorImageLoading = true;
      this.showImmExprCorImage = false;
      if (this.expandedColumn === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [
            collectionlist.immune_cor_expr.collnames[collectionlist.immune_cor_expr.cancertypes.indexOf(this.expandedElement.cancertype)],
          ],
          surType: [this.expandedElement.cell_type],
        };

        this.mutationApiService.getImmExprCorSingleGene(postTerm).subscribe(
          (res) => {
            this._createImageFromBlob(res, 'immExprCorSingleGeneImage');
            this.immExprCorSingleGeneImageLoading = false;
            this.showImmExprCorSingleGeneImage = true;
            this.showImmExprCorImage = false;
            this.immExprCorImageLoading = false;
          },
          (err) => {
            this.immExprCorSingleGeneImageLoading = false;
            this.showImmExprCorSingleGeneImage = false;
            this.immExprCorImageLoading = false;
            this.showImmExprCorImage = false;
          }
        );
      }
      if (this.expandedColumn === 'cancertype') {
        const postTerm = {
          validSymbol: this.searchTerm.validSymbol,
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [
            collectionlist.immune_cor_expr.collnames[collectionlist.immune_cor_expr.cancertypes.indexOf(this.expandedElement.cancertype)],
          ]
        };
        this.mutationApiService.getImmExprCorPlot(postTerm).subscribe(
          (res) => {
            this.showImmExprCorImage = true;
            this.immExprCorImageLoading = false;
            this.immExprCorSingleGeneImageLoading = false;
            this.showImmExprCorSingleGeneImage = false;
            this._createImageFromBlob(res, 'immExprCorImage');
          },
          (err) => {
            this.immExprCorImageLoading = false;
            this.showImmExprCorImage = false;
            this.immExprCorSingleGeneImageLoading = false;
            this.showImmExprCorSingleGeneImage = false;
          }
        );        
      }
    } else {
      this.immExprCorSingleGeneImageLoading = false;
      this.showImmExprCorSingleGeneImage = false;
      this.immExprCorImageLoading = false;
      this.showImmExprCorImage = false;
    }
  }
  public triggerDetail(element: ImmCorTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
}
