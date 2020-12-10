import { Component, OnInit, OnChanges, AfterViewInit, SimpleChanges, Input } from '@angular/core';
import { ExpressionApiService } from './../expression-api.service';
import { ExprSearch } from './../../../shared/model/exprsearch';
import collectionList from 'src/app/shared/constants/collectionlist';
import { MatTableDataSource } from '@angular/material/table';
import { GeneSetTableRecrod } from 'src/app/shared/model/genesettablerecord';

@Component({
  selector: 'app-gene-set',
  templateUrl: './gene-set.component.html',
  styleUrls: ['./gene-set.component.css'],
})
export class GeneSetComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  dataSourceGeneSetLoading = true;
  dataSourceGeneSet: MatTableDataSource<GeneSetTableRecrod>;
  showGeneSetTable = true;

  geneSetImage: any;
  geneSetPdfURL: string;
  geneSetImageLoading = true;
  showGeneSetImage = true;

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    this.dataSourceGeneSetLoading = true;
    this.geneSetImageLoading = true;
    const postTerm = this._validCollection(this.searchTerm);

    console.log(postTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceGeneSetLoading = false;
      this.geneSetImageLoading = false;
      this.showGeneSetTable = false;
      this.showGeneSetImage = false;
    } else {
      this.showGeneSetTable = true;
      this.expressionApiService.getGeneSetTable(postTerm).subscribe(
        (res) => {
          this.dataSourceGeneSetLoading = false;
          this.dataSourceGeneSet = new MatTableDataSource(res);
          console.log(res);
        },
        (err) => {
          this.showGeneSetTable = false;
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
          case 'geneSetImage':
            this.geneSetImage = reader.result;
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
