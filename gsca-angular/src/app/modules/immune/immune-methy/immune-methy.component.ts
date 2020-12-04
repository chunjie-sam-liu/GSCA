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
  selector: 'app-immune-methy',
  templateUrl: './immune-methy.component.html',
  styleUrls: ['./immune-methy.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class ImmuneMethyComponent implements  OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // immMethy cor table data source
  dataSourceImmMethyCorLoading = true;
  dataSourceImmMethyCor: MatTableDataSource<ImmCorTableRecord>;
  showImmMethyCorTable = true;
  @ViewChild('paginatorImmMethyCor') paginatorImmMethyCor: MatPaginator;
  @ViewChild(MatSort) sortImmMethyCor: MatSort;
  displayedColumnsImmMethyCor = ['cancertype', 'symbol', 'cell_type', 'cor', 'fdr'];
  displayedColumnsImmMethyCorHeader = [
    'Cancer type',
    'Gene symbol',
    "Cell type",
    'Correlation',
    'FDR',
  ];
  expandedElement: ImmCorTableRecord;
  expandedColumn: string;

  // immMethy cor plot
  immMethyCorImageLoading = true;
  immMethyCorImage: any;
  showImmMethyCorImage = true;

  // single gene cor
  immMethyCorSingleGeneImage: any;
  immMethyCorSingleGeneImageLoading = true;
  showImmMethyCorSingleGeneImage = false;

  constructor(private mutationApiService: ImmuneApiService) { }

  ngOnInit(): void {
  }

  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.dataSourceImmMethyCorLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceImmMethyCorLoading = false;
      this.showImmMethyCorTable = false;
    } else {
      this.showImmMethyCorTable = true;
      this.mutationApiService.getImmMethyCorTable(postTerm).subscribe(
        (res) => {
          this.dataSourceImmMethyCorLoading = false;
          this.dataSourceImmMethyCor = new MatTableDataSource(res);
          this.dataSourceImmMethyCor.paginator = this.paginatorImmMethyCor;
          this.dataSourceImmMethyCor.sort = this.sortImmMethyCor;
        },
        (err) => {
          this.dataSourceImmMethyCorLoading = false;
          this.showImmMethyCorTable = false;
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
          case 'immMethyCorImage':
            this.immMethyCorImage = reader.result;
            break;
          case 'immMethyCorSingleGeneImage':
            this.immMethyCorSingleGeneImage = reader.result;
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
        return collectionlist.immune_cor_methy.collnames[collectionlist.immune_cor_methy.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }
  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceImmMethyCor.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceImmMethyCor.paginator) {
      this.dataSourceImmMethyCor.paginator.firstPage();
    }
  }

  public expandDetail(element: ImmCorTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.immMethyCorSingleGeneImageLoading = true;
      this.showImmMethyCorSingleGeneImage = false;
      if (this.expandedColumn === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [
            collectionlist.immune_cor_methy.collnames[collectionlist.immune_cor_methy.cancertypes.indexOf(this.expandedElement.cancertype)],
          ],
          surType: [this.expandedElement.cell_type],
        };

        this.mutationApiService.getImmMethyCorSingleGene(postTerm).subscribe(
          (res) => {
            this._createImageFromBlob(res, 'immMethyCorSingleGeneImage');
            this.immMethyCorSingleGeneImageLoading = false;
            this.showImmMethyCorSingleGeneImage = true;
            this.immMethyCorImageLoading = false;
            this.showImmMethyCorImage = false;
          },
          (err) => {
            this.immMethyCorSingleGeneImageLoading = false;
            this.showImmMethyCorSingleGeneImage = false;
            this.immMethyCorImageLoading = false;
            this.showImmMethyCorImage = false;
          }
        );
      }
      if (this.expandedColumn === 'cancertype') {
        const postTerm = {
          validSymbol: this.searchTerm.validSymbol,
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [
            collectionlist.immune_cor_methy.collnames[collectionlist.immune_cor_methy.cancertypes.indexOf(this.expandedElement.cancertype)],
          ]
        };
        this.mutationApiService.getImmMethyCorPlot(postTerm).subscribe(
          (res) => {
            this.showImmMethyCorImage = true;
            this.immMethyCorImageLoading = false;
            this.immMethyCorSingleGeneImageLoading = false;
            this.showImmMethyCorSingleGeneImage = false;
            this._createImageFromBlob(res, 'immMethyCorImage');
          },
          (err) => {
            this.immMethyCorImageLoading = false;
            this.showImmMethyCorImage = false;
            this.immMethyCorSingleGeneImageLoading = false;
            this.showImmMethyCorSingleGeneImage = false;
          }
        );        
      }
    } else {
      this.immMethyCorSingleGeneImageLoading = false;
      this.showImmMethyCorSingleGeneImage = false;
      this.immMethyCorImageLoading = false;
      this.showImmMethyCorImage = false;
    }
  }
  public triggerDetail(element: ImmCorTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
}
