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
  selector: 'app-immune-snv',
  templateUrl: './immune-snv.component.html',
  styleUrls: ['./immune-snv.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class ImmuneSnvComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  
  // immSnv cor table data source
  dataSourceImmSnvCorLoading = true;
  dataSourceImmSnvCor: MatTableDataSource<ImmCorTableRecord>;
  showImmSnvCorTable = true;
  @ViewChild('paginatorImmSnvCor') paginatorImmSnvCor: MatPaginator;
  @ViewChild(MatSort) sortImmSnvCor: MatSort;
  displayedColumnsImmSnvCor = ['cancertype', 'symbol', 'cell_type','logfc', 'fdr'];
  displayedColumnsImmSnvCorHeader = [
    'Cancer type',
    'Gene symbol',
    'Cell type',
    'Log2(FC)',
    'FDR',
  ];
  expandedElement: ImmCorTableRecord;
  expandedColumn: string;

  // immSnv cor plot
  immSnvCorImageLoading = true;
  immSnvCorImage: any;
  showImmSnvCorImage = true;

  // single gene cor
  immSnvCorSingleGeneImage: any;
  immSnvCorSingleGeneImageLoading = true;
  showImmSnvCorSingleGeneImage = false;
  constructor(private mutationApiService: ImmuneApiService) { }

  ngOnInit(): void {
  }
  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.dataSourceImmSnvCorLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceImmSnvCorLoading = false;
      this.showImmSnvCorTable = false;
    } else {
      this.showImmSnvCorTable = true;
      this.mutationApiService.getImmSnvCorTable(postTerm).subscribe(
        (res) => {
          this.dataSourceImmSnvCorLoading = false;
          this.dataSourceImmSnvCor = new MatTableDataSource(res);
          this.dataSourceImmSnvCor.paginator = this.paginatorImmSnvCor;
          this.dataSourceImmSnvCor.sort = this.sortImmSnvCor;
        },
        (err) => {
          this.dataSourceImmSnvCorLoading = false;
          this.showImmSnvCorTable = false;
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
          case 'immSnvCorImage':
            this.immSnvCorImage = reader.result;
            break;
          case 'immSnvCorSingleGeneImage':
            this.immSnvCorSingleGeneImage = reader.result;
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
    this.dataSourceImmSnvCor.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceImmSnvCor.paginator) {
      this.dataSourceImmSnvCor.paginator.firstPage();
    }
  }

  public expandDetail(element: ImmCorTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.immSnvCorSingleGeneImageLoading = true;
      this.showImmSnvCorSingleGeneImage = false;
      if (this.expandedColumn === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [
            collectionlist.immune_cor_snv.collnames[collectionlist.immune_cor_snv.cancertypes.indexOf(this.expandedElement.cancertype)],
          ],
          surType: [this.expandedElement.cell_type],
        };

        this.mutationApiService.getImmSnvCorSingleGene(postTerm).subscribe(
          (res) => {
            this._createImageFromBlob(res, 'immSnvCorSingleGeneImage');
            this.immSnvCorSingleGeneImageLoading = false;
            this.showImmSnvCorSingleGeneImage = true;
            this.immSnvCorImageLoading = false;
            this.showImmSnvCorImage = false;
          },
          (err) => {
            this.immSnvCorSingleGeneImageLoading = false;
            this.showImmSnvCorSingleGeneImage = false;
            this.immSnvCorImageLoading = false;
            this.showImmSnvCorImage = false;
          }
        );
      }
      if (this.expandedColumn === 'cancertype') {
        const postTerm = {
          validSymbol: this.searchTerm.validSymbol,
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [
            collectionlist.immune_cor_snv.collnames[collectionlist.immune_cor_snv.cancertypes.indexOf(this.expandedElement.cancertype)],
          ]
        };
        this.mutationApiService.getImmSnvCorPlot(postTerm).subscribe(
          (res) => {
            this.showImmSnvCorImage = true;
            this.immSnvCorImageLoading = false;
            this.immSnvCorSingleGeneImageLoading = false;
            this.showImmSnvCorSingleGeneImage = false;
            this._createImageFromBlob(res, 'immSnvCorImage');
          },
          (err) => {
            this.immSnvCorImageLoading = false;
            this.showImmSnvCorImage = false;
            this.immSnvCorSingleGeneImageLoading = false;
            this.showImmSnvCorSingleGeneImage = false;
          }
        );        
      }
    } else {
      this.immSnvCorSingleGeneImageLoading = false;
      this.showImmSnvCorSingleGeneImage = false;
      this.immSnvCorImageLoading = false;
      this.showImmSnvCorImage = false;
    }
  }
  public triggerDetail(element: ImmCorTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
}
