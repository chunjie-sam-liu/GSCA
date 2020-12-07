import { AfterViewInit, Component, OnInit } from '@angular/core';
import { ExprSearch } from 'src/app/shared/model/exprsearch';

@Component({
  selector: 'app-expression',
  templateUrl: './expression.component.html',
  styleUrls: ['./expression.component.css'],
})
export class ExpressionComponent implements OnInit, AfterViewInit {
  searchTerm: ExprSearch;
  showDEG = false;
  showSurvival = false;
  showSubtype = false;
  showStage = false;

  constructor() {}

  ngOnInit(): void {}
  ngAfterViewInit(): void {}

  public showContent(exprSearch: ExprSearch): void {
    this.searchTerm = exprSearch;
    this.showDEG = true;
    this.showSurvival = true;
    this.showSubtype = true;
    this.showStage = true;
  }
}
