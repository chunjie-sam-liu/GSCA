import { Component, OnInit, ViewChild } from '@angular/core';
import { environment } from 'src/environments/environment';
import immunecellstable from 'src/app/shared/constants/immunecells';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';
import { ImmCellTableRecord } from 'src/app/shared/model/immcelltablerecord';
import { MatTableDataSource } from '@angular/material/table';
@Component({
  selector: 'app-document',
  templateUrl: './document.component.html',
  styleUrls: ['./document.component.css'],
})
export class DocumentComponent implements OnInit {
  public assets = environment.assets;
  public immunecells = immunecellstable;
  // immunecells: MatTableDataSource<ImmCellTableRecord>;
  /* @ViewChild('paginatorImm') paginatorImm: MatPaginator;
  @ViewChild(MatSort) sortImm: MatSort;
  public immtab = immunecellstable;

  immunecells = new MatTableDataSource(this.immtab);
  immunecells.paginator = paginatorImm;
  immunecells.sort = sortImm;
 */
  displayedColumnsImmuneCells = ['Immuneabbreviation', 'fullname'];
  displayedColumnsImmuneCellsHeader = ['Immune cells abbreviation', 'Immune cells fullname'];
  constructor() {}

  ngOnInit(): void {}
}
