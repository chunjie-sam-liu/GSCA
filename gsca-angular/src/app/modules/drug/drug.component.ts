import { AfterViewInit, Component, OnInit } from '@angular/core';
import { ExprSearch } from 'src/app/shared/model/exprsearch';

@Component({
  selector: 'app-drug',
  templateUrl: './drug.component.html',
  styleUrls: ['./drug.component.css'],
})
export class DrugComponent implements OnInit, AfterViewInit {
  searchTerm: ExprSearch;
  showList = {
    showGDSC: false,
    showCTRP: false,
    showContent: false,
  };
  constructor() {}

  ngOnInit(): void {}
  ngAfterViewInit(): void {}

  public showContent(exprSearch: ExprSearch): void {
    this.searchTerm = exprSearch;
  }
}
