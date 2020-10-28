import { Component, OnInit } from '@angular/core';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { ExpressionApiService } from './expression-api.service';

@Component({
  selector: 'app-expression',
  templateUrl: './expression.component.html',
  styleUrls: ['./expression.component.css'],
})
export class ExpressionComponent implements OnInit {
  searchTerm: ExprSearch;
  showDEG = false;

  constructor() {}

  ngOnInit(): void {}

  public showContent(exprSearch: ExprSearch): void {
    this.searchTerm = exprSearch;
    this.showDEG = true;
  }
}
