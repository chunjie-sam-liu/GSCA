import { AfterViewInit, Component, OnInit } from '@angular/core';
import { ExprSearch } from 'src/app/shared/model/exprsearch';

@Component({
  selector: 'app-immune',
  templateUrl: './immune.component.html',
  styleUrls: ['./immune.component.css']
})
export class ImmuneComponent implements OnInit, AfterViewInit {
  searchTerm: ExprSearch;
  showList = {
    showImmExpr : false,
    showImmSnv : false,
    showImmCnv : false,
    showImmMethy : false,
    showContent: false,
  }
  constructor() { }

  ngOnInit(): void {}
  ngAfterViewInit(): void {}
  
  public showContent(exprSearch: ExprSearch): void {
    this.searchTerm = exprSearch;
  }
}
