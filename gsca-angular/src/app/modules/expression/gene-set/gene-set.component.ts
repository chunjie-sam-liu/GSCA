import { Component, OnInit, OnChanges, AfterViewInit, SimpleChanges, Input } from '@angular/core';
import { ExpressionApiService } from './../expression-api.service';
import { ExprSearch } from './../../../shared/model/exprsearch';
import collectionList from 'src/app/shared/constants/collectionlist';
import { MatTableDataSource } from '@angular/material/table';
import { GSVATableRecord } from 'src/app/shared/model/gsvatablerecord';

@Component({
  selector: 'app-gene-set',
  templateUrl: './gene-set.component.html',
  styleUrls: ['./gene-set.component.css'],
})
export class GeneSetComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  dataSourceGSVALoading = true;
  dataSourceGSVA: MatTableDataSource<GSVATableRecord>;
  showGSVATable = true;

  GSVAImage: any;
  GSVAPdfURL: string;
  GSVAImageLoading = true;
  showGSVAImage = true;

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    this.dataSourceGSVALoading = true;
    this.GSVAImageLoading = true;
    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceGSVALoading = false;
      this.GSVAImageLoading = false;
      this.showGSVATable = false;
      this.showGSVAImage = false;
    } else {
      this.showGSVATable = true;
      this.expressionApiService.getGSVAAnalysis(postTerm).subscribe(
        (res) => {
          console.log(res);
          this.expressionApiService.getExprGSVAPlot(res.uuidname).subscribe((exprgsvauuids) => {
            console.log(exprgsvauuids);
            // get table through resource
            this.expressionApiService.getResourceTable('preanalysised_gsva_expr', exprgsvauuids.exprgsvatableuuid).subscribe((r) => {
              console.log(r);
            });
            // get image from response
            this.expressionApiService.getResourcePlotBlob(exprgsvauuids.exprgsvaplotuuid, 'png').subscribe((r) => {
              console.log(r);
              this.showGSVAImage = true;
              this.GSVAImageLoading = false;
              this._createImageFromBlob(r, 'GSVAImage');
            });
          });
        },
        (err) => {
          this.showGSVATable = false;
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
          case 'GSVAImage':
            this.GSVAImage = reader.result;
            break;
        }
      },
      false
    );
    if (res) {
      reader.readAsDataURL(res);
    }
  }
}
