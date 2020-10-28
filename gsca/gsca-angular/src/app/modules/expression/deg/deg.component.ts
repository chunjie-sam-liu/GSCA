import { Component, Input, OnChanges, OnInit, SimpleChanges } from '@angular/core';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { ExpressionApiService } from '../expression-api.service';

@Component({
  selector: 'app-deg',
  templateUrl: './deg.component.html',
  styleUrls: ['./deg.component.css'],
})
export class DegComponent implements OnInit, OnChanges {
  @Input() searchTerm: ExprSearch;

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    this.expressionApiService.getDEGTable(this.searchTerm);
  }
}
