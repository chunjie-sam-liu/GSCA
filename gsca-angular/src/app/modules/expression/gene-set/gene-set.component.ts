import { Component, OnInit, OnChanges, AfterViewInit, SimpleChanges, Input } from '@angular/core';
import { ExpressionApiService } from './../expression-api.service';
import { ExprSearch } from './../../../shared/model/exprsearch';
import collectionlist from 'src/app/shared/constants/collectionlist';

@Component({
  selector: 'app-gene-set',
  templateUrl: './gene-set.component.html',
  styleUrls: ['./gene-set.component.css'],
})
export class GeneSetComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {
    console.error(this.searchTerm);
  }

  ngOnChanges(changes: SimpleChanges): void {}

  ngAfterViewInit(): void {}

  private _validCollection(st: ExprSearch): any {
    return st;
  }
}
