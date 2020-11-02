import { AfterViewInit, Component, ElementRef, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { MatTableDataSource } from '@angular/material/table';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { SurvivalTableRecord } from 'src/app/shared/model/survivaltablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import collectionlist from 'src/app/shared/constants/collectionlist';
import { ExpressionApiService } from '../expression-api.service';

@Component({
  selector: 'app-survival',
  templateUrl: './survival.component.html',
  styleUrls: ['./survival.component.css'],
})
export class SurvivalComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // survival table data source
  dataSourceSurvivalLoading = true;
  dataSourceSurvival: MatTableDataSource<SurvivalTableRecord>;
  @ViewChild('paginatorSurvival', { static: true }) paginatorSurvival: MatPaginator;
  @ViewChild(MatSort) sortSurvival: MatSort;
  displayedColumnsSurvival = ['cancertype', 'symbol', 'pval', 'worse_group'];

  // survival plot
  survivalImageLoading = true;
  survivalImage: any;

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    // Called before any other lifecycle hook. Use it to inject dependencies, but avoid any serious work here.
    // Add '${implements OnChanges}' to the class.
    this.dataSourceSurvivalLoading = true;
    this.survivalImageLoading = true;
    const postTerm = this._validCollection(this.searchTerm);

    this.expressionApiService.getSurvivalTable(postTerm).subscribe((res) => {
      this.dataSourceSurvivalLoading = false;
      this.dataSourceSurvival = new MatTableDataSource(res);
      this.dataSourceSurvival.paginator = this.paginatorSurvival;
      this.dataSourceSurvival.sort = this.sortSurvival;
    });

    this.expressionApiService.getSurvivalPlot(postTerm).subscribe(
      (res) => {
        this.survivalImageLoading = false;
        this._createImageFromBlob(res);
      },
      (err) => {
        this.survivalImageLoading = false;
      }
    );
  }

  ngAfterViewInit(): void {
    // Called after ngAfterContentInit when the component's view has been initialized. Applies to components only.
    // Add 'implements AfterViewInit' to the class.
  }

  private _validCollection(st: ExprSearch): any {
    st.validColl = st.cancerTypeSelected
      .map((val) => {
        return collectionlist.expr_survival.collnames[collectionlist.expr_survival.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }

  private _createImageFromBlob(res: Blob) {
    const reader = new FileReader();
    reader.addEventListener(
      'load',
      () => {
        this.survivalImage = reader.result;
      },
      false
    );
    if (res) {
      reader.readAsDataURL(res);
    }
  }
  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceSurvival.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceSurvival.paginator) {
      this.dataSourceSurvival.paginator.firstPage();
    }
  }
}
