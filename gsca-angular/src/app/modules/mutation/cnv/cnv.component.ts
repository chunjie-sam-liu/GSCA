import { AfterViewInit, Component, ElementRef, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { CnvTableRecord } from 'src/app/shared/model/cnvtablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { MutationApiService } from '../mutation-api.service';
import { animate, state, style, transition, trigger } from '@angular/animations';

@Component({
  selector: 'app-cnv',
  templateUrl: './cnv.component.html',
  styleUrls: ['./cnv.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class CnvComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // cnv table data source
  dataSourceCnvLoading = true;
  dataSourceCnv: MatTableDataSource<CnvTableRecord>;
  showCnvTable = true;
  @ViewChild('paginatorCnv') paginatorCnv: MatPaginator;
  @ViewChild(MatSort) sortCnv: MatSort;
  displayedColumnsCnv = ['cancertype', 'symbol', 'a_total', 'd_total', 'a_hete', 'd_hete', 'a_homo', 'd_homo'];
  displayedColumnsCnvHeader = [
    'Cancer type',
    'Gene symbol',
    'Total amplification(%)',
    'Total deletion(%)',
    'Heterozygous amplification(%)',
    'Heterozygous deletion(%)',
    'Homozygous amplification(%)',
    'Homozygous deletion(%)',
  ];
  expandedElement: CnvTableRecord;
  expandedColumn: string;

  // cnv pie plot
  cnvPieImageLoading = true;
  cnvPieImage: any;
  showCnvPieImage = true;

  // cnv hete point plot
  cnvHetePointImageLoading = true;
  cnvHetePointImage: any;
  showCnvHetePointImage = true;

  // cnv homo point plot
  cnvHomoPointImageLoading = true;
  cnvHomoPointImage: any;
  showCnvHomoPointImage = true;

  // single gene cnv imgae
  cnvSingleGeneImage: any;
  showCnvSingleGeneImage = true;
  cnvSingleGeneImageLoading = true;

  constructor(private mutationApiService: MutationApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.dataSourceCnvLoading = true;
    this.cnvPieImageLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceCnvLoading = false;
      this.cnvPieImageLoading = false;
      this.showCnvTable = false;
      this.showCnvPieImage = false;
      this.showCnvHetePointImage = false;
      this.showCnvHomoPointImage = false;
    } else {
      // get cnvTable
      this.showCnvTable = true;
      this.mutationApiService.getCnvTable(postTerm).subscribe(
        (res) => {
          this.dataSourceCnvLoading = false;
          this.dataSourceCnv = new MatTableDataSource(res);
          this.dataSourceCnv.paginator = this.paginatorCnv;
          this.dataSourceCnv.sort = this.sortCnv;
        },
        (err) => {
          this.dataSourceCnvLoading = false;
          this.showCnvTable = false;
        }
      );
      // get cnvPiePlot
      this.mutationApiService.getCnvPiePlot(postTerm).subscribe(
        (res) => {
          this.showCnvPieImage = true;
          this.cnvPieImageLoading = false;
          this._createImageFromBlob(res, 'cnvPieImage');
        },
        (err) => {
          this.cnvPieImageLoading = false;
          this.showCnvPieImage = false;
        }
      );
      // get cnvHetePoint
      this.mutationApiService.getCnvHetePointImage(postTerm).subscribe(
        (res) => {
          this.showCnvHetePointImage = true;
          this.cnvHetePointImageLoading = false;
          this._createImageFromBlob(res, 'cnvHetePointImage');
        },
        (err) => {
          this.cnvHetePointImageLoading = false;
          this.showCnvHetePointImage = false;
        }
      );
      // get cnvHomoPoint
      this.mutationApiService.getCnvHomoPointImage(postTerm).subscribe(
        (res) => {
          this.showCnvHomoPointImage = true;
          this.cnvHomoPointImageLoading = false;
          this._createImageFromBlob(res, 'cnvHomoPointImage');
        },
        (err) => {
          this.cnvHomoPointImageLoading = false;
          this.showCnvHomoPointImage = false;
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
          case 'cnvPieImage':
            this.cnvPieImage = reader.result;
            break;
          case 'cnvSingleGeneImage':
            this.cnvSingleGeneImage = reader.result;
            break;
          case 'cnvHetePointImage':
            this.cnvHetePointImage = reader.result;
            break;
          case 'cnvHomoPointImage':
            this.cnvHomoPointImage = reader.result;
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
        return collectionlist.cnv_percent.collnames[collectionlist.cnv_percent.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }

  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceCnv.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceCnv.paginator) {
      this.dataSourceCnv.paginator.firstPage();
    }
  }

  public expandDetail(element: CnvTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.cnvSingleGeneImageLoading = true;
      this.showCnvSingleGeneImage = false;
      if (this.expandedColumn === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [
            collectionlist.cnv_threshold.collnames[collectionlist.cnv_threshold.cancertypes.indexOf(this.expandedElement.cancertype)],
          ],
        };

        this.mutationApiService.getCnvSingleGene(postTerm).subscribe(
          (res) => {
            this._createImageFromBlob(res, 'cnvSingleGeneImage');
            this.cnvSingleGeneImageLoading = false;
            this.showCnvSingleGeneImage = true;
          },
          (err) => {
            this.cnvSingleGeneImageLoading = false;
            this.showCnvSingleGeneImage = false;
          }
        );
      }
    } else {
      this.cnvSingleGeneImageLoading = false;
      this.showCnvSingleGeneImage = false;
    }
  }

  public triggerDetail(element: CnvTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
}
