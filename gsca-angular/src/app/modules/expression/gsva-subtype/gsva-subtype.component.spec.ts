import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { GsvaSubtypeComponent } from './gsva-subtype.component';

describe('GsvaSubtypeComponent', () => {
  let component: GsvaSubtypeComponent;
  let fixture: ComponentFixture<GsvaSubtypeComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ GsvaSubtypeComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(GsvaSubtypeComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
