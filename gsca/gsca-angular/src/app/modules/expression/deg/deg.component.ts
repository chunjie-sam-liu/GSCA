import { Component, Input, OnChanges, OnInit, SimpleChanges } from '@angular/core';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { ExpressionApiService } from '../expression-api.service';
import collectionList from 'src/app/shared/constants/collectionlist';

@Component({
  selector: 'app-deg',
  templateUrl: './deg.component.html',
  styleUrls: ['./deg.component.css'],
})
export class DegComponent implements OnInit, OnChanges {
  @Input() searchTerm: ExprSearch;

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    const postTerm = this._validCollection(this.searchTerm);
    console.log(postTerm);
    this.expressionApiService.getDEGTable(postTerm).subscribe((res) => {
      console.log(res);
    });
  }

  private _validCollection(st: ExprSearch): any {
    st.validColl = st.cancerTypeSelected
      .map((val) => {
        return collectionList.deg.collnames[collectionList.deg.cancertypes.indexOf(val)];
      })
      .filter(Boolean);

    return st;
  }
}
