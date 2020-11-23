import { AfterViewInit, Component, OnInit } from '@angular/core';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { SnvGeneset } from 'src/app/shared/model/snvgeneset';

@Component({
  selector: 'app-mutation',
  templateUrl: './mutation.component.html',
  styleUrls: ['./mutation.component.css'],
})
export class MutationComponent implements OnInit, AfterViewInit {
  searchTerm: ExprSearch;
  searchTermGeneset: SnvGeneset;
  showSnv = false;
  showSnvSurvival = false;
  constructor() {}

  ngOnInit(): void {}
  ngAfterViewInit(): void {}

  public showContent(exprSearch: ExprSearch, snvGeneset: SnvGeneset): void {
    this.searchTerm = exprSearch;
    this.searchTermGeneset = snvGeneset;
    this.showSnv = true;
    this.showSnvSurvival = true;
  }
}
