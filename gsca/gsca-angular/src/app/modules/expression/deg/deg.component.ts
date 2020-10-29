import { AfterViewInit, Component, ElementRef, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { ExpressionApiService } from '../expression-api.service';
import collectionList from 'src/app/shared/constants/collectionlist';
import { MatTableDataSource } from '@angular/material/table';
import { DegTableRecord } from 'src/app/shared/model/degtablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';

@Component({
  selector: 'app-deg',
  templateUrl: './deg.component.html',
  styleUrls: ['./deg.component.css'],
})
export class DegComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // deg table data source
  dataSourceDeg: MatTableDataSource<DegTableRecord>;
  @ViewChild('paginatorDeg', { static: true }) paginatorDeg: MatPaginator;
  @ViewChild(MatSort) sortDeg: MatSort;
  displayedColumnsDeg = ['cancertype', 'symbol', 'tumor', 'normal', 'fc', 'fdr', 'n_tumor'];

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    const postTerm = this._validCollection(this.searchTerm);

    this.expressionApiService.getDEGTable(postTerm).subscribe((res) => {
      this.dataSourceDeg = new MatTableDataSource(res);
      this.dataSourceDeg.paginator = this.paginatorDeg;
      this.dataSourceDeg.sort = this.sortDeg;
    });
  }

  ngAfterViewInit(): void {}

  private _validCollection(st: ExprSearch): any {
    st.validColl = st.cancerTypeSelected
      .map((val) => {
        return collectionList.deg.collnames[collectionList.deg.cancertypes.indexOf(val)];
      })
      .filter(Boolean);

    return st;
  }
  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceDeg.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceDeg.paginator) {
      this.dataSourceDeg.paginator.firstPage();
    }
  }
}
