import { AfterViewInit, Component, ElementRef, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { CnvCorTableRecord } from 'src/app/shared/model/cnvcortablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { MutationApiService } from '../mutation-api.service';
import { animate, state, style, transition, trigger } from '@angular/animations';

@Component({
  selector: 'app-cnv-cor',
  templateUrl: './cnv-cor.component.html',
  styleUrls: ['./cnv-cor.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class CnvCorComponent implements OnInit, OnChanges, AfterViewInit  {
  @Input() searchTerm: ExprSearch;

    // cnv cor table data source
    dataSourceCnvCorLoading = true;
    dataSourceCnvCor: MatTableDataSource<CnvCorTableRecord>;
    showCnvCorTable = true;
    @ViewChild('paginatorCnvCor') paginatorCnvCor: MatPaginator;
    @ViewChild(MatSort) sortCnvCor: MatSort;
    displayedColumnsCnvCor = ['cancertype', 'symbol', 'spm', 'fdr'];
    displayedColumnsCnvCorHeader = [
      'Cancer type',
      'Gene symbol',
      'Spearman correlation',
      'FDR',
    ];
    expandedElement: CnvCorTableRecord;
    expandedColumn: string;
  
    // cnv cor plot
    cnvCorImageLoading = true;
    cnvCorImage: any;
    showCnvCorImage = true;
  
    // single gene cor
    cnvCorSingleGeneImage: any;
    cnvCorSingleGeneImageLoading = true;
    showCnvCorSingleGeneImage = false;

  constructor(private mutationApiService: MutationApiService) { }

  ngOnInit(): void {
  }
  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.dataSourceCnvCorLoading = true;
    this.cnvCorImageLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceCnvCorLoading = false;
      this.cnvCorImageLoading = false;
      this.showCnvCorTable = false;
      this.showCnvCorImage = false;
    } else {
      this.showCnvCorTable = true;
      this.mutationApiService.getCnvCorTable(postTerm).subscribe(
        (res) => {
          this.dataSourceCnvCorLoading = false;
          this.dataSourceCnvCor = new MatTableDataSource(res);
          this.dataSourceCnvCor.paginator = this.paginatorCnvCor;
          this.dataSourceCnvCor.sort = this.sortCnvCor;
        },
        (err) => {
          this.dataSourceCnvCorLoading = false;
          this.showCnvCorTable = false;
        }
      );

      this.mutationApiService.getCnvCorPlot(postTerm).subscribe(
        (res) => {
          this.showCnvCorImage = true;
          this.cnvCorImageLoading = false;
          this._createImageFromBlob(res, 'cnvCorImage');
        },
        (err) => {
          this.cnvCorImageLoading = false;
          this.showCnvCorImage = false;
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
          case 'cnvCorImage':
            this.cnvCorImage = reader.result;
            break;
          case 'cnvCorSingleGeneImage':
            this.cnvCorSingleGeneImage = reader.result;
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
        return collectionlist.cnv_cor_expr.collnames[collectionlist.cnv_cor_expr.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }
  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceCnvCor.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceCnvCor.paginator) {
      this.dataSourceCnvCor.paginator.firstPage();
    }
  }

  public expandDetail(element: CnvCorTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.cnvCorSingleGeneImageLoading = true;
      this.showCnvCorSingleGeneImage = false;
      if (this.expandedColumn === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [
            collectionlist.all_cnv.collnames[collectionlist.all_cnv.cancertypes.indexOf(this.expandedElement.cancertype)],
          ]
        };

        this.mutationApiService.getCnvCorSingleGene(postTerm).subscribe(
          (res) => {
            this._createImageFromBlob(res, 'cnvCorSingleGeneImage');
            this.cnvCorSingleGeneImageLoading = false;
            this.showCnvCorSingleGeneImage = true;
          },
          (err) => {
            this.cnvCorSingleGeneImageLoading = false;
            this.showCnvCorSingleGeneImage = false;
          }
        );
      }
    } else {
      this.cnvCorSingleGeneImageLoading = false;
      this.showCnvCorSingleGeneImage = false;
    }
  }
  public triggerDetail(element: CnvCorTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
}
