import { Component, Input, OnInit } from '@angular/core';
import { ExprSearch } from 'src/app/shared/model/exprsearch';

@Component({
  selector: 'app-deg',
  templateUrl: './deg.component.html',
  styleUrls: ['./deg.component.css'],
})
export class DegComponent implements OnInit {
  @Input() searchTerm: ExprSearch;

  constructor() {}

  ngOnInit(): void {}
}
