import { AfterViewInit, Component, ElementRef, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { SnvTableRecord } from 'src/app/shared/model/snvtablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { MutationApiService } from '../mutation-api.service';
import { animate, state, style, transition, trigger } from '@angular/animations';

@Component({
  selector: 'app-snv',
  templateUrl: './snv.component.html',
  styleUrls: ['./snv.component.css'],
  animations: [
    trigger('detailExpand', [
      state('collapsed', style({ height: '0px', minHeight: '0' })),
      state('expanded', style({ height: '*' })),
      transition('expanded <=> collapsed', animate('225ms cubic-bezier(0.4, 0.0, 0.2, 1)')),
    ]),
  ],
})
export class SnvComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // snv table data source
  dataSourceSnvLoading = true;
  dataSourceSnv: MatTableDataSource<SnvTableRecord>;
  showSnvTable = true;
  @ViewChild('paginatorSnv') paginatorSnv: MatPaginator;
  @ViewChild(MatSort) sortSnv: MatSort;
  displayedColumnsSnv = ['cancertype', 'symbol', 'mutated_sample_size', 'sample_size', 'percentage'];
  displayedColumnsSnvHeader = ['Cancer type', 'Gene symbol', 'Mutated sample size', 'Total sample size', 'Percentage'];
  expandedElement: SnvTableRecord;
  expandedColumn: string;

  // snv plot
  snvImageLoading = true;
  snvImage: any;
  showSnvImage = true;

  // single gene lolliplot
  snvSingleGeneImage: any;
  snvSingleGeneImageLoading = true;
  showSnvSingleGeneImage = false;

  constructor(private mutationApiService: MutationApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.dataSourceSnvLoading = true;
    this.snvImageLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceSnvLoading = false;
      this.snvImageLoading = false;
      this.showSnvTable = false;
      this.showSnvImage = false;
    } else {
      this.showSnvTable = true;
      this.mutationApiService.getSnvTable(postTerm).subscribe(
        (res) => {
          this.dataSourceSnvLoading = false;
          this.dataSourceSnv = new MatTableDataSource(res);
          this.dataSourceSnv.paginator = this.paginatorSnv;
          this.dataSourceSnv.sort = this.sortSnv;
        },
        (err) => {
          this.dataSourceSnvLoading = false;
          this.showSnvTable = false;
        }
      );

      this.mutationApiService.getSnvPlot(postTerm).subscribe(
        (res) => {
          this.showSnvImage = true;
          this.snvImageLoading = false;
          this._createImageFromBlob(res, 'snvImage');
        },
        (err) => {
          this.snvImageLoading = false;
          this.showSnvImage = false;
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
          case 'snvImage':
            this.snvImage = reader.result;
            break;
          case 'snvSingleGeneImage':
            this.snvSingleGeneImage = reader.result;
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
        return collectionlist.snv_count.collnames[collectionlist.snv_count.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }

  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceSnv.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceSnv.paginator) {
      this.dataSourceSnv.paginator.firstPage();
    }
  }

  public expandDetail(element: SnvTableRecord, column: string): void {
    this.expandedElement = this.expandedElement === element && this.expandedColumn === column ? null : element;
    this.expandedColumn = column;

    if (this.expandedElement) {
      this.snvSingleGeneImageLoading = true;
      this.showSnvSingleGeneImage = false;
      if (this.expandedColumn === 'symbol') {
        const postTerm = {
          validSymbol: [this.expandedElement.symbol],
          cancerTypeSelected: [this.expandedElement.cancertype],
          validColl: [collectionlist.snv_count.collnames[collectionlist.snv_count.cancertypes.indexOf(this.expandedElement.cancertype)]],
        };

        this.mutationApiService.getSnvLollipop(postTerm).subscribe(
          (res) => {
            this._createImageFromBlob(res, 'snvSingleGeneImage');
            this.snvSingleGeneImageLoading = false;
            this.showSnvSingleGeneImage = true;
          },
          (err) => {
            this.snvSingleGeneImageLoading = false;
            this.showSnvSingleGeneImage = false;
          }
        );
      }
    } else {
      this.snvSingleGeneImageLoading = false;
      this.showSnvSingleGeneImage = false;
    }
  }

  public triggerDetail(element: SnvTableRecord): string {
    return element === this.expandedElement ? 'expanded' : 'collapsed';
  }
}
