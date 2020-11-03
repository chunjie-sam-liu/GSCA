import { AfterViewInit, Component, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
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
  dataSourceDegLoading = true;
  dataSourceDeg: MatTableDataSource<DegTableRecord>;
  @ViewChild('paginatorDeg') paginatorDeg: MatPaginator;
  @ViewChild(MatSort) sortDeg: MatSort;
  displayedColumnsDeg = ['cancertype', 'symbol', 'tumor', 'normal', 'fc', 'fdr', 'n_tumor'];

  // degPlot
  degImageLoading = true;
  degImage: any;
  showDEGTable = true;
  showDEGImage = true;

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    this.dataSourceDegLoading = true;
    this.degImageLoading = true;

    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceDegLoading = false;
      this.degImageLoading = false;
      this.showDEGTable = false;
      this.showDEGImage = false;
    } else {
      this.showDEGTable = true;
      this.expressionApiService.getDEGTable(postTerm).subscribe(
        (res) => {
          this.dataSourceDegLoading = false;
          this.dataSourceDeg = new MatTableDataSource(res);
          this.dataSourceDeg.paginator = this.paginatorDeg;
          this.dataSourceDeg.sort = this.sortDeg;
        },
        (err) => {
          this.showDEGTable = false;
        }
      );

      this.expressionApiService.getDEGPlot(postTerm).subscribe(
        (res) => {
          this.showDEGImage = true;
          this.degImageLoading = false;
          this._createImageFromBlob(res);
        },
        (err) => {
          this.showDEGImage = false;
        }
      );
    }
  }

  ngAfterViewInit(): void {}

  private _createImageFromBlob(res: Blob) {
    const reader = new FileReader();
    reader.addEventListener(
      'load',
      () => {
        this.degImage = reader.result;
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
