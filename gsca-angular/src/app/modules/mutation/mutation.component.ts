import { AfterViewInit, Component, OnInit } from '@angular/core';
import { ExprSearch } from 'src/app/shared/model/exprsearch';

@Component({
  selector: 'app-mutation',
  templateUrl: './mutation.component.html',
  styleUrls: ['./mutation.component.css'],
})
export class MutationComponent implements OnInit, AfterViewInit {
  searchTerm: ExprSearch;
  showSnv = false;
  showSnvSurvival = false;
  showMethylation = false;
  showMethylationSurvival = false;
  showMethylationCor = false;
  showCnv = false;
  showCnvSurvival = false;
  showCnvCor = false;
  constructor() {}

  ngOnInit(): void {}
  ngAfterViewInit(): void {}

  public showContent(exprSearch: ExprSearch): void {
    this.searchTerm = exprSearch;
    this.showSnv = true;
    this.showSnvSurvival = true;
    this.showMethylation = true;
    this.showMethylationSurvival = true;
    this.showMethylationCor = true;
    this.showCnv = true;
    this.showCnvSurvival = true;
    this.showCnvCor = true;
  }
}
