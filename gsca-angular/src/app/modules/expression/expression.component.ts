import { AfterViewInit, Component, OnInit } from '@angular/core';
import { ExprSearch } from 'src/app/shared/model/exprsearch';

@Component({
  selector: 'app-expression',
  templateUrl: './expression.component.html',
  styleUrls: ['./expression.component.css'],
})
export class ExpressionComponent implements OnInit, AfterViewInit {
  searchTerm: ExprSearch;
  showSelected = false;
  showList = {
    showDEG: false,
    showSurvival: false,
    showSubtype: false,
    showStage: false,
  };

  constructor() {}

  ngOnInit(): void {}
  ngAfterViewInit(): void {}

  public showContent(exprSearch: ExprSearch): void {
    this.searchTerm = exprSearch;
    this.showSelected = true;
  }
}
