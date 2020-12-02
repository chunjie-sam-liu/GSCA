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
  selector: 'app-immune-cnv',
  templateUrl: './immune-cnv.component.html',
  styleUrls: ['./immune-cnv.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class ImmuneCnvComponent implements  OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  
  // immCnv cor table data source
  dataSourceImmCnvCorLoading = true;
  dataSourceImmCnvCor: MatTableDataSource<ImmCorTableRecord>;
  showImmCnvCorTable = true;
  @ViewChild('paginatorImmCnvCor') paginatorImmCnvCor: MatPaginator;
  @ViewChild(MatSort) sortImmCnvCor: MatSort;
  displayedColumnsImmCnvCor = ['cancertype', 'symbol', 'spm', 'fdr'];
  displayedColumnsImmCnvCorHeader = [
    'Cancer type',
    'Gene symbol',
    'Spearman correlation',
    'FDR',
  ];
  expandedElement: ImmCorTableRecord;
  expandedColumn: string;

  // immCnv cor plot
  immCnvCorImageLoading = true;
  immCnvCorImage: any;
  showImmCnvCorImage = true;

  // single gene cor
  immCnvCorSingleGeneImage: any;
  immCnvCorSingleGeneImageLoading = true;
  showImmCnvCorSingleGeneImage = false;

  constructor(private mutationApiService: ImmuneApiService) { }

  ngOnInit(): void {
  }
  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.dataSourceImmCnvCorLoading = true;
    this.immCnvCorImageLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceImmCnvCorLoading = false;
      this.immCnvCorImageLoading = false;
      this.showImmCnvCorTable = false;
      this.showImmCnvCorImage = false;
    } else {
      this.showImmCnvCorTable = true;
      this.mutationApiService.getImmCnvCorTable(postTerm).subscribe(
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

      this.mutationApiService.getImmCnvCorPlot(postTerm).subscribe(
        (res) => {
          this.showImmCnvCorImage = true;
          this.immCnvCorImageLoading = false;
          this._createImageFromBlob(res, 'immCnvCorImage');
        },
        (err) => {
          this.immCnvCorImageLoading = false;
          this.showImmCnvCorImage = false;
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
      if (this.expandedColumn === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [
            collectionlist.immune_cor_cnv.collnames[collectionlist.immune_cor_cnv.cancertypes.indexOf(this.expandedElement.cancertype)],
          ]
        };

        this.mutationApiService.getImmCnvCorSingleGene(postTerm).subscribe(
          (res) => {
            this._createImageFromBlob(res, 'immCnvCorSingleGeneImage');
            this.immCnvCorSingleGeneImageLoading = false;
            this.showImmCnvCorSingleGeneImage = true;
          },
          (err) => {
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