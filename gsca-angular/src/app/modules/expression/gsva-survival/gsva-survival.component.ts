import { Component, OnInit, OnChanges, AfterViewInit, SimpleChanges, Input, ViewChild } from '@angular/core';
import { ExpressionApiService } from './../expression-api.service';
import { ExprSearch } from './../../../shared/model/exprsearch';
import collectionList from 'src/app/shared/constants/collectionlist';
import { MatTableDataSource } from '@angular/material/table';
import { GSVASurvivalTableRecord } from 'src/app/shared/model/gsvasurvivaltablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';

@Component({
  selector: 'app-gsva-survival',
  templateUrl: './gsva-survival.component.html',
  styleUrls: ['./gsva-survival.component.css'],
})
export class GsvaSurvivalComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  // GSVA survival table
  dataSourceGSVASurvivalLoading = true;
  dataSourceGSVASurvival: MatTableDataSource<GSVASurvivalTableRecord>;
  showGSVASurvivalTable = true;
  @ViewChild('paginatorGSVASurvival') paginatorGSVASurvival: MatPaginator;
  @ViewChild(MatSort) sortGSVASurvival: MatSort;
  displayedColumnsGSVASurvival = ['cancertype', 'sur_type', 'hr_categorical', 'coxp_categorical', 'logrankp', 'higher_risk_of_death'];
  displayedColumnsGSVASurvivalHeader = [
    'Cancer type',
    'Survival type',
    'Hazard Ratio',
    'Cox P value',
    'Logrank P value',
    'Higher risk of death',
  ];

  // GSVA survival image
  GSVASurvivalImage: any;
  GSVASurvivalPdfURL: string;
  GSVASurvivalImageLoading = true;
  showGSVASurvivalImage = true;
  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    this.dataSourceGSVASurvivalLoading = true;
    this.GSVASurvivalImageLoading = true;
    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceGSVASurvivalLoading = false;
      this.GSVASurvivalImageLoading = false;
      this.showGSVASurvivalTable = false;
      this.showGSVASurvivalImage = false;
    } else {
      this.expressionApiService.getGSVAAnalysis(postTerm).subscribe(
        (res) => {
          this.expressionApiService.getExprSurvivalGSVAPlot(res.uuidname).subscribe(
            (exprgsvauuids) => {
              this.showGSVASurvivalTable = true;
              this.expressionApiService.getResourceTable('preanalysised_gsva_survival', exprgsvauuids.exprsurvivalgsvatableuuid).subscribe(
                (r) => {
                  this.dataSourceGSVASurvivalLoading = false;
                  this.dataSourceGSVASurvival = new MatTableDataSource(r);
                  this.dataSourceGSVASurvival.paginator = this.paginatorGSVASurvival;
                  this.dataSourceGSVASurvival.sort = this.sortGSVASurvival;
                },
                (e) => {
                  this.showGSVASurvivalTable = false;
                }
              );
              this.GSVASurvivalPdfURL = this.expressionApiService.getResourcePlotURL(exprgsvauuids.exprsurvivalgsvaplotuuid, 'pdf');
              this.expressionApiService.getResourcePlotBlob(exprgsvauuids.exprsurvivalgsvaplotuuid, 'png').subscribe(
                (r) => {
                  this.showGSVASurvivalImage = true;
                  this.GSVASurvivalImageLoading = false;
                  this._createImageFromBlob(r, 'GSVASurvivalImage');
                },
                (e) => {
                  this.showGSVASurvivalImage = false;
                }
              );
            },
            (e) => {
              this.dataSourceGSVASurvivalLoading = false;
              this.GSVASurvivalImageLoading = false;
              this.showGSVASurvivalTable = false;
              this.showGSVASurvivalImage = false;
            }
          );
        },
        (err) => {
          this.showGSVASurvivalTable = false;
          this.showGSVASurvivalImage = false;
        }
      );
    }
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

  private _createImageFromBlob(res: Blob, present: string) {
    const reader = new FileReader();
    reader.addEventListener(
      'load',
      () => {
        switch (present) {
          case 'GSVASurvivalImage':
            this.GSVASurvivalImage = reader.result;
            break;
        }
      },
      false
    );
    if (res) {
      reader.readAsDataURL(res);
    }
  }

  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceGSVASurvival.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceGSVASurvival.paginator) {
      this.dataSourceGSVASurvival.paginator.firstPage();
    }
  }
}
