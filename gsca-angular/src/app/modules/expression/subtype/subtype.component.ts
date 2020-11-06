import { Component, Input, OnInit, ViewChild, OnChanges, SimpleChanges, AfterViewChecked } from '@angular/core';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { MatTableDataSource } from '@angular/material/table';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { SubtypeTableRecord } from 'src/app/shared/model/subtypetablerecord';
import { ExpressionApiService } from '../expression-api.service';

@Component({
  selector: 'app-subtype',
  templateUrl: './subtype.component.html',
  styleUrls: ['./subtype.component.css'],
})
export class SubtypeComponent implements OnInit, OnChanges, AfterViewChecked {
  @Input() searchTerm: ExprSearch;

  // subtype table
  subtypeTableLoading = true;
  subtypeTable: MatTableDataSource<SubtypeTableRecord>;
  showSubtypeTable = true;
  @ViewChild('paginatorSubtype') paginatorSubtype: MatPaginator;
  @ViewChild(MatSort) sortSubtype: MatSort;
  displayedColumnsSubtype = ['cancertype', 'symbol', 'pval', 'fdr'];

  // subtype image
  subtypeImageLoading = true;
  subtypeImage: any;
  showSubtypeImage = true;

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.subtypeImageLoading = true;
    this.subtypeTableLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.subtypeImageLoading = false;
      this.subtypeTableLoading = false;
      this.showSubtypeImage = false;
      this.showSubtypeTable = false;
    } else {
      this.showSubtypeTable = true;
      this.expressionApiService.getSubtypeTable(postTerm).subscribe(
        (res) => {
          this.subtypeTableLoading = false;
          this.subtypeTable = new MatTableDataSource(res);
          this.subtypeTable.paginator = this.paginatorSubtype;
          this.subtypeTable.sort = this.sortSubtype;
        },
        (err) => {
          this.showSubtypeTable = false;
          this.subtypeTableLoading = false;
        }
      );
      this.expressionApiService.getSubtypePlot(postTerm).subscribe(
        (res) => {
          this.showSubtypeImage = true;
          this.subtypeImageLoading = false;
          this._createImageFromBlob(res);
        },
        (err) => {
          this.showSubtypeImage = false;
          this.subtypeImageLoading = false;
        }
      );
    }
  }

  ngAfterViewChecked(): void {
    // Called after every check of the component's view. Applies to components only.
    // Add 'implements AfterViewChecked' to the class.
  }

  private _validCollection(st: ExprSearch): any {
    st.validColl = st.cancerTypeSelected
      .map((val) => {
        return collectionlist.expr_subtype.collnames[collectionlist.expr_subtype.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }
  private _createImageFromBlob(res: Blob) {
    const reader = new FileReader();
    reader.addEventListener(
      'load',
      () => {
        this.subtypeImage = reader.result;
      },
      false
    );
    if (res) {
      reader.readAsDataURL(res);
    }
  }
  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.subtypeTable.filter = filterValue.trim().toLowerCase();

    if (this.subtypeTable.paginator) {
      this.subtypeTable.paginator.firstPage();
    }
  }
}
