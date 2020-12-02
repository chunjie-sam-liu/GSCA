import { AfterViewInit, Component, OnInit } from '@angular/core';
import { ExprSearch } from 'src/app/shared/model/exprsearch';

@Component({
  selector: 'app-immune',
  templateUrl: './immune.component.html',
  styleUrls: ['./immune.component.css']
})
export class ImmuneComponent implements OnInit {
  searchTerm: ExprSearch;
  showImmExpr = false;
  showImmSnv = false;
  showImmCnv = false;
  showImmMethy = false;
  constructor() { }

  ngOnInit(): void {}
  ngAfterViewInit(): void {}
  
  public showContent(exprSearch: ExprSearch): void {
    this.searchTerm = exprSearch;
    this.showImmExpr = true;
    this.showImmSnv = true;
    this.showImmCnv = true;
    this.showImmMethy = true;
  }
}
