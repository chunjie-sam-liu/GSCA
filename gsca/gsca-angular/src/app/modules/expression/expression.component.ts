import { Component, OnInit } from '@angular/core';
import { ExprSearch } from 'src/app/shared/model/exprsearch';

@Component({
  selector: 'app-expression',
  templateUrl: './expression.component.html',
  styleUrls: ['./expression.component.css'],
})
export class ExpressionComponent implements OnInit {
  searchSymbol: string[];
  selectedCancerTypes: string[];

  constructor() {}

  ngOnInit(): void {}

  public showContent(exprSearch: ExprSearch): void {
    this.searchSymbol = exprSearch.validSymbol;
    this.selectedCancerTypes = exprSearch.cancerTypesSelected;
  }
}
